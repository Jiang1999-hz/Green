import SwiftUI

@main
struct GreenApp: App {
    private let appContainer: AppContainer
    private let plantDashboardViewModel: PlantDashboardViewModel

    init() {
        let appContainer = AppContainer()
        self.appContainer = appContainer
        self.plantDashboardViewModel = appContainer.makePlantDashboardViewModel()
    }

    var body: some Scene {
        WindowGroup {
            PlantDashboardView(
                container: appContainer,
                viewModel: plantDashboardViewModel
            )
        }
    }
}
