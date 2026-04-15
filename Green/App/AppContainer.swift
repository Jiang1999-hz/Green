import Foundation

@MainActor
final class AppContainer {
    static let preview = AppContainer(persistenceController: .preview)

    let persistenceController: PersistenceController
    let plantRepository: any PlantRepository
    let photoLibraryService: PhotoLibraryService

    init(
        persistenceController: PersistenceController = .shared,
        plantRepository: (any PlantRepository)? = nil,
        photoLibraryService: PhotoLibraryService = PhotoLibraryService()
    ) {
        self.persistenceController = persistenceController
        self.plantRepository = plantRepository ?? CoreDataPlantRepository(
            context: persistenceController.container.viewContext
        )
        self.photoLibraryService = photoLibraryService
    }

    func makePlantDashboardViewModel() -> PlantDashboardViewModel {
        PlantDashboardViewModel(plantRepository: plantRepository)
    }

    func makePlantDetailViewModel(plantID: UUID) -> PlantDetailViewModel {
        PlantDetailViewModel(
            plantID: plantID,
            plantRepository: plantRepository
        )
    }

    func makeCreatePlantViewModel() -> PlantFormViewModel {
        PlantFormViewModel(
            mode: .create,
            plantRepository: plantRepository,
            photoLibraryService: photoLibraryService
        )
    }

    func makeEditPlantViewModel(plant: PlantRecord) -> PlantFormViewModel {
        PlantFormViewModel(
            mode: .edit(plant.id),
            draft: PlantDraft(plant: plant),
            plantRepository: plantRepository,
            photoLibraryService: photoLibraryService
        )
    }
}
