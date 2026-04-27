import Foundation

struct PlantDetailState: Equatable {
    var plant: PlantRecord?
    var growthRecords: [GrowthRecordEntry] = []
    var reminderSnapshot: WateringReminderSnapshot?
    var isLoading = false
    var isRefreshingReminder = false
    var errorMessage: String?

    var recentGrowthRecords: [GrowthRecordEntry] {
        Array(growthRecords.prefix(5))
    }

    var hasMoreGrowthRecords: Bool {
        growthRecords.count > recentGrowthRecords.count
    }

    var growthJourneyStage: GrowthJourneyStage {
        GrowthJourneyStage(recordCount: growthRecords.count)
    }
}

@MainActor
final class PlantDetailViewModel: ObservableObject {
    @Published private(set) var state = PlantDetailState()

    let plantID: UUID

    private let plantRepository: any PlantRepository
    private let growthRecordRepository: any GrowthRecordRepository
    private let wateringReminderService: WateringReminderService

    init(
        plantID: UUID,
        plantRepository: any PlantRepository,
        growthRecordRepository: any GrowthRecordRepository,
        wateringReminderService: WateringReminderService
    ) {
        self.plantID = plantID
        self.plantRepository = plantRepository
        self.growthRecordRepository = growthRecordRepository
        self.wateringReminderService = wateringReminderService
    }

    func load() async {
        state.isLoading = true

        do {
            state.plant = try plantRepository.fetchPlant(id: plantID)
            if state.plant == nil {
                state.growthRecords = []
                state.reminderSnapshot = nil
                state.errorMessage = "植物档案不存在或已被删除。"
            } else {
                state.growthRecords = try growthRecordRepository.fetchGrowthRecords(plantID: plantID)
                if let plant = state.plant {
                    state.reminderSnapshot = await wateringReminderService.reminderSnapshot(for: plant)
                }
                state.errorMessage = nil
            }
        } catch {
            state.plant = nil
            state.growthRecords = []
            state.reminderSnapshot = nil
            state.errorMessage = "植物档案加载失败，请稍后重试。"
        }

        state.isLoading = false
    }

    func enableOrRefreshReminder() async -> Bool {
        guard let plant = state.plant else {
            return false
        }

        state.isRefreshingReminder = true
        defer { state.isRefreshingReminder = false }

        do {
            let snapshot = try await wateringReminderService.ensureReminder(for: plant)
            state.reminderSnapshot = snapshot
            state.errorMessage = nil
            return snapshot.permissionState.allowsScheduling && snapshot.isScheduled
        } catch {
            state.errorMessage = "浇水提醒更新失败，请稍后重试。"
            return false
        }
    }

    func refreshReminderSnapshot() async {
        guard let plant = state.plant else {
            return
        }

        state.isRefreshingReminder = true
        defer { state.isRefreshingReminder = false }
        state.reminderSnapshot = await wateringReminderService.reminderSnapshot(for: plant)
    }

    func markPlantWateredNow() async -> Bool {
        state.isRefreshingReminder = true
        defer { state.isRefreshingReminder = false }

        do {
            let updatedPlant = try plantRepository.markPlantWatered(id: plantID, at: .now)
            state.plant = updatedPlant
            state.reminderSnapshot = try await wateringReminderService.ensureReminder(for: updatedPlant)
            state.errorMessage = nil
            return true
        } catch {
            state.errorMessage = "更新浇水状态失败，请稍后重试。"
            return false
        }
    }

    func deletePlant() -> Bool {
        do {
            try plantRepository.deletePlant(id: plantID)
            Task {
                try? await wateringReminderService.cancelReminder(for: plantID)
            }
            state.errorMessage = nil
            return true
        } catch {
            state.errorMessage = "删除植物档案失败，请稍后重试。"
            return false
        }
    }
}
