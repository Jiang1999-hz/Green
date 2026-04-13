import UserNotifications

enum NotificationPermissionState: Equatable {
    case notDetermined
    case denied
    case authorized
    case provisional
    case ephemeral
}

struct NotificationPermissionService {
    func currentStatus() async -> NotificationPermissionState {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return map(settings.authorizationStatus)
    }

    func requestAuthorizationIfNeeded() async throws -> NotificationPermissionState {
        let current = await currentStatus()
        guard current == .notDetermined else {
            return current
        }

        let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
        return granted ? .authorized : .denied
    }

    private func map(_ status: UNAuthorizationStatus) -> NotificationPermissionState {
        switch status {
        case .notDetermined:
            return .notDetermined
        case .denied:
            return .denied
        case .authorized:
            return .authorized
        case .provisional:
            return .provisional
        case .ephemeral:
            return .ephemeral
        @unknown default:
            return .denied
        }
    }
}
