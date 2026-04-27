import Foundation

struct PlantDraft: Equatable, Sendable {
    var name: String
    var species: String
    var location: String
    var plantedDate: Date
    var wateringIntervalDays: Int
    var lastWateredDate: Date?
    var nextWateringDate: Date?
    var notes: String
    var coverPhotoAssetIdentifier: String?

    init(
        name: String = "",
        species: String = "",
        location: String = "",
        plantedDate: Date = .now,
        wateringIntervalDays: Int = 7,
        lastWateredDate: Date? = nil,
        nextWateringDate: Date? = nil,
        notes: String = "",
        coverPhotoAssetIdentifier: String? = nil
    ) {
        self.name = name
        self.species = species
        self.location = location
        self.plantedDate = plantedDate
        self.wateringIntervalDays = wateringIntervalDays
        self.lastWateredDate = lastWateredDate
        self.nextWateringDate = nextWateringDate
        self.notes = notes
        self.coverPhotoAssetIdentifier = coverPhotoAssetIdentifier
    }

    init(plant: PlantRecord) {
        self.init(
            name: plant.name,
            species: plant.species ?? "",
            location: plant.location ?? "",
            plantedDate: plant.plantedDate,
            wateringIntervalDays: plant.wateringIntervalDays,
            lastWateredDate: plant.lastWateredDate,
            nextWateringDate: plant.nextWateringDate,
            notes: plant.notes ?? "",
            coverPhotoAssetIdentifier: plant.coverPhotoAssetIdentifier
        )
    }

    var normalizedName: String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "未命名植物" : trimmed
    }

    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var normalizedSpecies: String? {
        species.trimmedOrNil
    }

    var normalizedLocation: String? {
        location.trimmedOrNil
    }

    var normalizedNotes: String? {
        notes.trimmedOrNil
    }
}

private extension String {
    var trimmedOrNil: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
