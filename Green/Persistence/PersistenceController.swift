import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    static let preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext

        let plant = Plant(context: context)
        plant.id = UUID()
        plant.name = "龟背竹"
        plant.species = "Monstera deliciosa"
        plant.location = "客厅落地窗"
        plant.plantedDate = Calendar.current.date(byAdding: .day, value: -42, to: .now) ?? .now
        plant.wateringIntervalDays = 5
        plant.nextWateringDate = Calendar.current.date(byAdding: .day, value: 2, to: .now)
        plant.createdAt = .now
        plant.updatedAt = .now

        do {
            try context.save()
        } catch {
            fatalError("Failed to seed preview data: \(error.localizedDescription)")
        }

        return controller
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "GreenModel")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { _, error in
            if let error {
                fatalError("Unresolved CoreData error: \(error.localizedDescription)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
}
