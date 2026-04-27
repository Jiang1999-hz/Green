import Combine
import Foundation

struct PlantDashboardState: Equatable {
    var plants: [PlantRecord] = []
    var isLoading = false
    var isUpdatingNotificationPermission = false
    var errorMessage: String?
    var reminderPermissionState: NotificationPermissionState = .notDetermined
    var scheduledReminderCount = 0

    var plantCountText: String {
        "\(plants.count) 株"
    }

    var dueTodayCount: Int {
        plants.filter(\.isWateringDueToday).count
    }

    var dueTodayText: String {
        "\(dueTodayCount) 株今日需浇水"
    }

    var wateredTodayCount: Int {
        plants.filter(\.isWateredToday).count
    }

    var wateredTodayText: String {
        "\(wateredTodayCount) 株今日已浇水"
    }

    var wateringProgressDetailText: String {
        if plants.isEmpty {
            return "创建植物后，这里会汇总今天待浇水和已完成的状态。"
        }

        if dueTodayCount == 0 && wateredTodayCount == 0 {
            return "今天暂时没有到期浇水的植物。"
        }

        if dueTodayCount == 0 {
            return "今天到期的植物都已处理完成。"
        }

        if wateredTodayCount == 0 {
            return "今天还有 \(dueTodayCount) 株植物待浇水。"
        }

        return "今天已完成 \(wateredTodayCount) 株，还有 \(dueTodayCount) 株待浇水。"
    }

    var notificationsEnabled: Bool {
        reminderPermissionState.allowsScheduling
    }

    var reminderSummaryText: String {
        switch reminderPermissionState {
        case .authorized, .provisional, .ephemeral:
            return "\(scheduledReminderCount) 株已安排提醒"
        case .notDetermined:
            return "提醒待开启"
        case .denied:
            return "通知未开启"
        }
    }

    var reminderDetailText: String {
        switch reminderPermissionState {
        case .authorized, .provisional, .ephemeral:
            return scheduledReminderCount == 0
                ? "通知权限已开启，但当前还没有待触发的浇水提醒。"
                : "已接入系统通知，后续会按当前浇水节奏推送提醒。"
        case .notDetermined:
            return "进入植物详情后可直接开启通知提醒。"
        case .denied:
            return "系统通知权限已关闭，当前不会收到浇水提醒。"
        }
    }

    var emptySummaryText: String {
        "先创建第一株植物，后续浇水提醒和成长记录都会围绕植物档案展开。"
    }

    var showsEmptyState: Bool {
        !isLoading && plants.isEmpty && errorMessage == nil
    }
}

@MainActor
final class PlantDashboardViewModel: ObservableObject {
    @Published private(set) var state = PlantDashboardState()

    private let plantRepository: any PlantRepository
    private let wateringReminderService: WateringReminderService
    private var isObserving = false

    init(
        plantRepository: any PlantRepository,
        wateringReminderService: WateringReminderService
    ) {
        self.plantRepository = plantRepository
        self.wateringReminderService = wateringReminderService
    }

    func observePlants() async {
        guard !isObserving else {
            return
        }

        isObserving = true
        defer { isObserving = false }

        if state.plants.isEmpty {
            state.isLoading = true
        }

        do {
            for try await plants in plantRepository.observePlants() {
                state.plants = plants
                await refreshReminderState(for: plants)
                state.isLoading = false
                state.errorMessage = nil
            }
        } catch {
            guard !Task.isCancelled else {
                return
            }

            state.isLoading = false
            state.errorMessage = "植物档案加载失败，请稍后重试。"
        }
    }

    func refreshNotificationPermissionState() async {
        state.reminderPermissionState = await wateringReminderService.currentPermissionState()
    }

    func requestNotificationPermissionIfNeeded() async {
        state.isUpdatingNotificationPermission = true
        defer { state.isUpdatingNotificationPermission = false }

        do {
            state.reminderPermissionState = try await wateringReminderService.requestPermissionIfNeeded()
            state.errorMessage = nil
        } catch {
            state.errorMessage = "通知权限请求失败，请稍后重试。"
        }
    }

    private func refreshReminderState(for plants: [PlantRecord]) async {
        let snapshots = await wateringReminderService.reminderSnapshots(for: plants)
        let permissionState = snapshots.values.first?.permissionState ?? .notDetermined

        state.reminderPermissionState = permissionState
        state.scheduledReminderCount = snapshots.values.filter(\.isScheduled).count
    }
}
