import SwiftUI

@main
struct GreenApp: App {
    private let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            PlantDashboardView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
