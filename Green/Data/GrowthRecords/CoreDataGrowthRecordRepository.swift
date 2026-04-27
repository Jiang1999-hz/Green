import CoreData
import Foundation

@MainActor
final class CoreDataGrowthRecordRepository: GrowthRecordRepository {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func fetchGrowthRecords(plantID: UUID) throws -> [GrowthRecordEntry] {
        let request = GrowthRecord.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \GrowthRecord.recordedAt, ascending: false)]
        request.predicate = NSPredicate(format: "plant.id == %@", plantID as CVarArg)
        return try context.fetch(request).map(mapGrowthRecord)
    }

    func fetchGrowthRecord(id: UUID) throws -> GrowthRecordEntry? {
        try fetchGrowthRecordObject(id: id).map(mapGrowthRecord)
    }

    func createGrowthRecord(for plantID: UUID, from draft: GrowthRecordDraft) throws -> GrowthRecordEntry {
        guard let plant = try fetchPlantObject(id: plantID) else {
            throw GrowthRecordRepositoryError.plantNotFound(plantID)
        }

        guard let photoAssetIdentifier = draft.photoAssetIdentifier, !photoAssetIdentifier.isEmpty else {
            throw GrowthRecordRepositoryError.invalidPhotoAssetIdentifier
        }

        let growthRecord = GrowthRecord(context: context)
        growthRecord.id = UUID()
        growthRecord.createdAt = .now
        growthRecord.recordedAt = draft.recordedAt
        growthRecord.note = draft.normalizedNote
        growthRecord.photoAssetIdentifier = photoAssetIdentifier
        growthRecord.plant = plant

        try saveContext()
        return mapGrowthRecord(growthRecord)
    }

    func updateGrowthRecord(id: UUID, with draft: GrowthRecordDraft) throws -> GrowthRecordEntry {
        guard let growthRecord = try fetchGrowthRecordObject(id: id) else {
            throw GrowthRecordRepositoryError.growthRecordNotFound(id)
        }

        guard let photoAssetIdentifier = draft.photoAssetIdentifier, !photoAssetIdentifier.isEmpty else {
            throw GrowthRecordRepositoryError.invalidPhotoAssetIdentifier
        }

        growthRecord.recordedAt = draft.recordedAt
        growthRecord.note = draft.normalizedNote
        growthRecord.photoAssetIdentifier = photoAssetIdentifier

        try saveContext()
        return mapGrowthRecord(growthRecord)
    }

    func deleteGrowthRecord(id: UUID) throws {
        guard let growthRecord = try fetchGrowthRecordObject(id: id) else {
            throw GrowthRecordRepositoryError.growthRecordNotFound(id)
        }

        context.delete(growthRecord)
        try saveContext()
    }

    private func fetchPlantObject(id: UUID) throws -> Plant? {
        let request = Plant.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        return try context.fetch(request).first
    }

    private func fetchGrowthRecordObject(id: UUID) throws -> GrowthRecord? {
        let request = GrowthRecord.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        return try context.fetch(request).first
    }

    private func mapGrowthRecord(_ growthRecord: GrowthRecord) -> GrowthRecordEntry {
        GrowthRecordEntry(
            id: growthRecord.id,
            plantID: growthRecord.plant.id,
            recordedAt: growthRecord.recordedAt,
            note: growthRecord.note,
            photoAssetIdentifier: growthRecord.photoAssetIdentifier,
            heightCM: growthRecord.heightCM?.doubleValue,
            healthStatusRaw: growthRecord.healthStatusRaw,
            visionSummary: growthRecord.visionSummary,
            createdAt: growthRecord.createdAt
        )
    }

    private func saveContext() throws {
        guard context.hasChanges else {
            return
        }

        try context.save()
    }
}
