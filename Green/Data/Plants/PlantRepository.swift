import Foundation

enum PlantRepositoryError: LocalizedError {
    case plantNotFound(UUID)

    var errorDescription: String? {
        switch self {
        case let .plantNotFound(id):
            return "Plant \(id.uuidString) was not found."
        }
    }
}

@MainActor
protocol PlantRepository {
    func fetchPlants() throws -> [PlantRecord]
    func observePlants() -> AsyncThrowingStream<[PlantRecord], Error>
    func fetchPlant(id: UUID) throws -> PlantRecord?
    @discardableResult
    func createPlant(from draft: PlantDraft) throws -> PlantRecord
    @discardableResult
    func updatePlant(id: UUID, with draft: PlantDraft) throws -> PlantRecord
    func deletePlant(id: UUID) throws
}
