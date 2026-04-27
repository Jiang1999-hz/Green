import Foundation
import UserNotifications

struct WateringReminderSnapshot: Equatable, Sendable {
    let plantID: UUID
    let permissionState: NotificationPermissionState
    let targetDate: Date?
    let scheduledDate: Date?

    var isScheduled: Bool {
        scheduledDate != nil
    }

    var statusLabel: String {
        if !permissionState.allowsScheduling {
            switch permissionState {
            case .notDetermined:
                return "提醒待开启"
            case .denied:
                return "通知未开启"
            case .authorized, .provisional, .ephemeral:
                break
            }
        }

        if isScheduled {
            return "提醒已安排"
        }

        if targetDate == nil {
            return "暂无提醒日期"
        }

        return "提醒待安排"
    }

    var detailLabel: String {
        if !permissionState.allowsScheduling {
            switch permissionState {
            case .notDetermined:
                return "开启系统通知后，Green 才能按浇水节奏推送提醒。"
            case .denied:
                return "系统通知权限已关闭，需要到系统设置里重新开启。"
            case .authorized, .provisional, .ephemeral:
                break
            }
        }

        if let scheduledDate {
            return "当前提醒预计在 \(scheduledDate.formatted(date: .abbreviated, time: .shortened)) 触发。"
        }

        if let targetDate {
            return "当前计划浇水日是 \(targetDate.formatted(date: .abbreviated, time: .omitted))，可以重新安排提醒。"
        }

        return "当前植物还没有可用于安排提醒的浇水日期。"
    }

    var scheduledDateLabel: String {
        guard let scheduledDate else {
            return "未安排"
        }

        return scheduledDate.formatted(date: .abbreviated, time: .shortened)
    }
}

struct WateringReminderService {
    private let notificationCenter: UNUserNotificationCenter
    private let permissionService: NotificationPermissionService

    init(
        notificationCenter: UNUserNotificationCenter = .current(),
        permissionService: NotificationPermissionService = NotificationPermissionService()
    ) {
        self.notificationCenter = notificationCenter
        self.permissionService = permissionService
    }

    func scheduleReminder(for plant: PlantRecord) async throws {
        try await cancelReminder(for: plant.id)

        guard let nextWateringDate = plant.nextWateringDate else {
            return
        }

        let permissionState = try await permissionService.requestAuthorizationIfNeeded()
        guard permissionState == .authorized || permissionState == .provisional || permissionState == .ephemeral else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "该给\(plant.displayName)浇水了"
        content.body = "按当前养护节奏，今天适合检查一下土壤湿度并完成浇水。"
        content.sound = .default

        let triggerDate = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: nextWateringDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        let request = UNNotificationRequest(
            identifier: reminderIdentifier(for: plant.id),
            content: content,
            trigger: trigger
        )

        try await notificationCenter.add(request)
    }

    func currentPermissionState() async -> NotificationPermissionState {
        await permissionService.currentStatus()
    }

    func requestPermissionIfNeeded() async throws -> NotificationPermissionState {
        try await permissionService.requestAuthorizationIfNeeded()
    }

    func ensureReminder(for plant: PlantRecord) async throws -> WateringReminderSnapshot {
        let permissionState = try await permissionService.requestAuthorizationIfNeeded()
        guard permissionState.allowsScheduling else {
            return await reminderSnapshot(for: plant, permissionState: permissionState)
        }

        try await scheduleReminder(for: plant)
        return await reminderSnapshot(for: plant, permissionState: permissionState)
    }

    func reminderSnapshot(for plant: PlantRecord) async -> WateringReminderSnapshot {
        let permissionState = await permissionService.currentStatus()
        return await reminderSnapshot(for: plant, permissionState: permissionState)
    }

    func reminderSnapshots(for plants: [PlantRecord]) async -> [UUID: WateringReminderSnapshot] {
        let permissionState = await permissionService.currentStatus()
        let pendingRequests = await pendingReminderRequests()
        let scheduledDates = Dictionary(
            uniqueKeysWithValues: pendingRequests.compactMap { request -> (UUID, Date)? in
                guard
                    let plantID = plantID(from: request.identifier),
                    let scheduledDate = scheduledDate(from: request.trigger)
                else {
                    return nil
                }

                return (plantID, scheduledDate)
            }
        )

        return Dictionary(
            uniqueKeysWithValues: plants.map { plant in
                (
                    plant.id,
                    WateringReminderSnapshot(
                        plantID: plant.id,
                        permissionState: permissionState,
                        targetDate: plant.nextWateringDate,
                        scheduledDate: scheduledDates[plant.id]
                    )
                )
            }
        )
    }

    func cancelReminder(for plantID: UUID) async throws {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [reminderIdentifier(for: plantID)])
    }

    private func reminderSnapshot(
        for plant: PlantRecord,
        permissionState: NotificationPermissionState
    ) async -> WateringReminderSnapshot {
        let request = await pendingReminderRequest(for: plant.id)
        return WateringReminderSnapshot(
            plantID: plant.id,
            permissionState: permissionState,
            targetDate: plant.nextWateringDate,
            scheduledDate: scheduledDate(from: request?.trigger)
        )
    }

    private func pendingReminderRequest(for plantID: UUID) async -> UNNotificationRequest? {
        await pendingReminderRequests().first { $0.identifier == reminderIdentifier(for: plantID) }
    }

    private func pendingReminderRequests() async -> [UNNotificationRequest] {
        await withCheckedContinuation { continuation in
            notificationCenter.getPendingNotificationRequests { requests in
                continuation.resume(returning: requests.filter { $0.identifier.hasPrefix("watering-reminder-") })
            }
        }
    }

    private func scheduledDate(from trigger: UNNotificationTrigger?) -> Date? {
        if let calendarTrigger = trigger as? UNCalendarNotificationTrigger {
            return Calendar.current.date(from: calendarTrigger.dateComponents)
        }

        return nil
    }

    private func reminderIdentifier(for plantID: UUID) -> String {
        "watering-reminder-\(plantID.uuidString)"
    }

    private func plantID(from identifier: String) -> UUID? {
        let prefix = "watering-reminder-"
        guard identifier.hasPrefix(prefix) else {
            return nil
        }

        return UUID(uuidString: String(identifier.dropFirst(prefix.count)))
    }
}
