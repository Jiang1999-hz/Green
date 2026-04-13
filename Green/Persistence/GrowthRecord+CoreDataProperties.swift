import CoreData

extension GrowthRecord {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<GrowthRecord> {
        NSFetchRequest<GrowthRecord>(entityName: "GrowthRecord")
    }

    @NSManaged public var createdAt: Date
    @NSManaged public var healthStatusRaw: String?
    @NSManaged public var heightCM: NSNumber?
    @NSManaged public var id: UUID
    @NSManaged public var note: String?
    @NSManaged public var photoAssetIdentifier: String
    @NSManaged public var recordedAt: Date
    @NSManaged public var visionSummary: String?
    @NSManaged public var plant: Plant

    var recordedDateLabel: String {
        recordedAt.formatted(date: .abbreviated, time: .omitted)
    }
}

extension GrowthRecord: Identifiable {}
