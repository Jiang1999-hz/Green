import CoreData

extension Plant {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Plant> {
        NSFetchRequest<Plant>(entityName: "Plant")
    }

    @NSManaged public var coverPhotoAssetIdentifier: String?
    @NSManaged public var createdAt: Date
    @NSManaged public var id: UUID
    @NSManaged public var lastWateredDate: Date?
    @NSManaged public var location: String?
    @NSManaged public var name: String
    @NSManaged public var nextWateringDate: Date?
    @NSManaged public var notes: String?
    @NSManaged public var plantedDate: Date
    @NSManaged public var species: String?
    @NSManaged public var updatedAt: Date
    @NSManaged public var wateringIntervalDays: Int16
    @NSManaged public var records: NSSet?

    @objc(addRecordsObject:)
    @NSManaged public func addToRecords(_ value: GrowthRecord)

    @objc(removeRecordsObject:)
    @NSManaged public func removeFromRecords(_ value: GrowthRecord)

    @objc(addRecords:)
    @NSManaged public func addToRecords(_ values: NSSet)

    @objc(removeRecords:)
    @NSManaged public func removeFromRecords(_ values: NSSet)

    var wrappedName: String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "未命名植物" : trimmed
    }

    var wrappedLocation: String {
        guard let location, !location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return "位置待补充"
        }

        return location
    }

    var daysSincePlanted: Int {
        Calendar.current.dateComponents([.day], from: plantedDate, to: .now).day ?? 0
    }

    var nextWateringLabel: String {
        guard let nextWateringDate else {
            return "提醒待接入"
        }

        return "下次 \(nextWateringDate.formatted(date: .numeric, time: .omitted))"
    }
}

extension Plant: Identifiable {}
