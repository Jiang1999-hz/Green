import Foundation

enum GrowthRecordRepositoryError: LocalizedError {
    case plantNotFound(UUID)
    case growthRecordNotFound(UUID)
    case invalidPhotoAssetIdentifier

    var errorDescription: String? {
        switch self {
        case let .plantNotFound(id):
            return "Plant \(id.uuidString) was not found."
        case let .growthRecordNotFound(id):
            return "GrowthRecord \(id.uuidString) was not found."
        case .invalidPhotoAssetIdentifier:
            return "A growth record photo asset identifier is required."
        }
    }
}

@MainActor
protocol GrowthRecordRepository {
    func fetchGrowthRecords(plantID: UUID) throws -> [GrowthRecordEntry]
    func fetchGrowthRecord(id: UUID) throws -> GrowthRecordEntry?

    @discardableResult
    func createGrowthRecord(for plantID: UUID, from draft: GrowthRecordDraft) throws -> GrowthRecordEntry

    @discardableResult
    func updateGrowthRecord(id: UUID, with draft: GrowthRecordDraft) throws -> GrowthRecordEntry

    func deleteGrowthRecord(id: UUID) throws
}
