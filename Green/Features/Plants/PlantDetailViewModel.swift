import Foundation

struct PlantDetailState: Equatable {
    var plant: PlantRecord?
    var isLoading = false
    var errorMessage: String?
}

@MainActor
final class PlantDetailViewModel: ObservableObject {
    @Published private(set) var state = PlantDetailState()

    let plantID: UUID

    private let plantRepository: any PlantRepository

    init(
        plantID: UUID,
        plantRepository: any PlantRepository
    ) {
        self.plantID = plantID
        self.plantRepository = plantRepository
    }

    func load() {
        state.isLoading = true

        do {
            state.plant = try plantRepository.fetchPlant(id: plantID)
            state.errorMessage = state.plant == nil ? "植物档案不存在或已被删除。" : nil
        } catch {
            state.plant = nil
            state.errorMessage = "植物档案加载失败，请稍后重试。"
        }

        state.isLoading = false
    }

    func deletePlant() -> Bool {
        do {
            try plantRepository.deletePlant(id: plantID)
            state.errorMessage = nil
            return true
        } catch {
            state.errorMessage = "删除植物档案失败，请稍后重试。"
            return false
        }
    }
}
