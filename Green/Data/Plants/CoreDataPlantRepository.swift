import CoreData
import Foundation

@MainActor
final class CoreDataPlantRepository: PlantRepository {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func fetchPlants() throws -> [PlantRecord] {
        try context.fetch(makeFetchRequest()).map(mapPlant)
    }

    func observePlants() -> AsyncThrowingStream<[PlantRecord], Error> {
        AsyncThrowingStream { continuation in
            do {
                continuation.yield(try fetchPlants())
            } catch {
                continuation.finish(throwing: error)
                return
            }

            let notifications = NotificationCenter.default.notifications(
                named: .NSManagedObjectContextObjectsDidChange,
                object: context
            )

            let task = Task { @MainActor in
                do {
                    for await _ in notifications {
                        if Task.isCancelled {
                            break
                        }

                        continuation.yield(try fetchPlants())
                    }

                    continuation.finish()
                } catch {
                    guard !Task.isCancelled else {
                        continuation.finish()
                        return
                    }

                    continuation.finish(throwing: error)
                }
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    func fetchPlant(id: UUID) throws -> PlantRecord? {
        try fetchPlantObject(id: id).map(mapPlant)
    }

    func createPlant(from draft: PlantDraft) throws -> PlantRecord {
        let plant = Plant(context: context)
        apply(draft, to: plant, isNew: true)
        try saveContext()
        return mapPlant(plant)
    }

    func updatePlant(id: UUID, with draft: PlantDraft) throws -> PlantRecord {
        guard let plant = try fetchPlantObject(id: id) else {
            throw PlantRepositoryError.plantNotFound(id)
        }

        apply(draft, to: plant, isNew: false)
        try saveContext()
        return mapPlant(plant)
    }

    func markPlantWatered(id: UUID, at date: Date) throws -> PlantRecord {
        guard let plant = try fetchPlantObject(id: id) else {
            throw PlantRepositoryError.plantNotFound(id)
        }

        plant.lastWateredDate = date
        plant.nextWateringDate = PlantWateringSchedule.nextWateringDate(
            intervalDays: Int(plant.wateringIntervalDays),
            lastWateredDate: date
        )
        plant.updatedAt = .now

        try saveContext()
        return mapPlant(plant)
    }

    func deletePlant(id: UUID) throws {
        guard let plant = try fetchPlantObject(id: id) else {
            throw PlantRepositoryError.plantNotFound(id)
        }

        context.delete(plant)
        try saveContext()
    }

    private func makeFetchRequest() -> NSFetchRequest<Plant> {
        let request = Plant.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Plant.createdAt, ascending: false)]
        return request
    }

    private func fetchPlantObject(id: UUID) throws -> Plant? {
        let request = Plant.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        return try context.fetch(request).first
    }

    private func mapPlant(_ plant: Plant) -> PlantRecord {
        PlantRecord(
            id: plant.id,
            name: plant.name,
            species: plant.species,
            location: plant.location,
            plantedDate: plant.plantedDate,
            wateringIntervalDays: Int(plant.wateringIntervalDays),
            lastWateredDate: plant.lastWateredDate,
            nextWateringDate: plant.nextWateringDate,
            notes: plant.notes,
            coverPhotoAssetIdentifier: plant.coverPhotoAssetIdentifier,
            createdAt: plant.createdAt,
            updatedAt: plant.updatedAt
        )
    }

    private func apply(_ draft: PlantDraft, to plant: Plant, isNew: Bool) {
        if isNew {
            plant.id = UUID()
            plant.createdAt = .now
        }

        plant.name = draft.normalizedName
        plant.species = draft.normalizedSpecies
        plant.location = draft.normalizedLocation
        plant.plantedDate = draft.plantedDate
        plant.wateringIntervalDays = Int16(clamping: draft.wateringIntervalDays)
        plant.lastWateredDate = draft.lastWateredDate
        plant.nextWateringDate = draft.nextWateringDate
        plant.notes = draft.normalizedNotes
        plant.coverPhotoAssetIdentifier = draft.coverPhotoAssetIdentifier
        plant.updatedAt = .now
    }

    private func saveContext() throws {
        guard context.hasChanges else {
            return
        }

        try context.save()
    }
}
