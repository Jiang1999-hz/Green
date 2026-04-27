import Foundation

@MainActor
final class AppContainer {
    static let preview = AppContainer(persistenceController: .preview)

    let persistenceController: PersistenceController
    let plantRepository: any PlantRepository
    let growthRecordRepository: any GrowthRecordRepository
    let photoLibraryService: PhotoLibraryService
    let growthThemePreferenceStore: any GrowthThemePreferenceStore
    let notificationPermissionService: NotificationPermissionService
    let wateringReminderService: WateringReminderService
    let growthAnimationService: GrowthAnimationService

    init(
        persistenceController: PersistenceController = .shared,
        plantRepository: (any PlantRepository)? = nil,
        growthRecordRepository: (any GrowthRecordRepository)? = nil,
        photoLibraryService: PhotoLibraryService = PhotoLibraryService(),
        growthThemePreferenceStore: (any GrowthThemePreferenceStore)? = nil,
        notificationPermissionService: NotificationPermissionService = NotificationPermissionService(),
        wateringReminderService: WateringReminderService? = nil,
        growthAnimationService: GrowthAnimationService = GrowthAnimationService()
    ) {
        self.persistenceController = persistenceController
        self.plantRepository = plantRepository ?? CoreDataPlantRepository(
            context: persistenceController.container.viewContext
        )
        self.growthRecordRepository = growthRecordRepository ?? CoreDataGrowthRecordRepository(
            context: persistenceController.container.viewContext
        )
        self.photoLibraryService = photoLibraryService
        self.growthThemePreferenceStore = growthThemePreferenceStore ?? UserDefaultsGrowthThemePreferenceStore()
        self.notificationPermissionService = notificationPermissionService
        self.wateringReminderService = wateringReminderService ?? WateringReminderService(
            permissionService: notificationPermissionService
        )
        self.growthAnimationService = growthAnimationService
    }

    func makePlantDashboardViewModel() -> PlantDashboardViewModel {
        PlantDashboardViewModel(
            plantRepository: plantRepository,
            wateringReminderService: wateringReminderService
        )
    }

    func makePlantDetailViewModel(plantID: UUID) -> PlantDetailViewModel {
        PlantDetailViewModel(
            plantID: plantID,
            plantRepository: plantRepository,
            growthRecordRepository: growthRecordRepository,
            wateringReminderService: wateringReminderService
        )
    }

    func makeCreatePlantViewModel() -> PlantFormViewModel {
        PlantFormViewModel(
            mode: .create,
            plantRepository: plantRepository,
            photoLibraryService: photoLibraryService,
            wateringReminderService: wateringReminderService
        )
    }

    func makeEditPlantViewModel(plant: PlantRecord) -> PlantFormViewModel {
        PlantFormViewModel(
            mode: .edit(plant.id),
            draft: PlantDraft(plant: plant),
            plantRepository: plantRepository,
            photoLibraryService: photoLibraryService,
            wateringReminderService: wateringReminderService
        )
    }

    func makeCreateGrowthRecordViewModel(plantID: UUID) -> GrowthRecordFormViewModel {
        GrowthRecordFormViewModel(
            mode: .create(plantID),
            plantID: plantID,
            growthRecordRepository: growthRecordRepository,
            photoLibraryService: photoLibraryService
        )
    }

    func makeEditGrowthRecordViewModel(record: GrowthRecordEntry) -> GrowthRecordFormViewModel {
        GrowthRecordFormViewModel(
            mode: .edit(record.id),
            plantID: record.plantID,
            draft: GrowthRecordDraft(
                recordedAt: record.recordedAt,
                note: record.note ?? "",
                photoAssetIdentifier: record.photoAssetIdentifier
            ),
            growthRecordRepository: growthRecordRepository,
            photoLibraryService: photoLibraryService
        )
    }

    func makeGrowthRecordsOverviewViewModel(plant: PlantRecord) -> GrowthRecordsOverviewViewModel {
        GrowthRecordsOverviewViewModel(
            plant: plant,
            growthRecordRepository: growthRecordRepository,
            growthThemePreferenceStore: growthThemePreferenceStore,
            photoLibraryService: photoLibraryService,
            growthAnimationService: growthAnimationService
        )
    }
}
