import Combine
import Foundation

struct PlantDashboardState: Equatable {
    var plants: [PlantRecord] = []
    var isLoading = false
    var errorMessage: String?

    var plantCountText: String {
        "\(plants.count) 株"
    }

    var dueTodayCount: Int {
        plants.filter(\.isWateringDueToday).count
    }

    var dueTodayText: String {
        "\(dueTodayCount) 株今日需浇水"
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
    private var isObserving = false

    init(plantRepository: any PlantRepository) {
        self.plantRepository = plantRepository
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
}
