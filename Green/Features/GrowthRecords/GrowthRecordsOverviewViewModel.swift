import Foundation

struct GrowthRecordsOverviewState: Equatable {
    var growthRecords: [GrowthRecordEntry] = []
    var selectedThemeKind: GrowthTheme.Kind = .defaultGarden
    var isLoading = false
    var isExportingAnimation = false
    var exportProgress: Double = 0
    var exportStatusMessage: String?
    var exportedVideoURL: URL?
    var errorMessage: String?
}

@MainActor
final class GrowthRecordsOverviewViewModel: ObservableObject {
    @Published private(set) var state = GrowthRecordsOverviewState()

    let plant: PlantRecord

    private let growthRecordRepository: any GrowthRecordRepository
    private let growthThemePreferenceStore: any GrowthThemePreferenceStore
    private let photoLibraryService: PhotoLibraryService
    private let growthAnimationService: GrowthAnimationService

    init(
        plant: PlantRecord,
        growthRecordRepository: any GrowthRecordRepository,
        growthThemePreferenceStore: any GrowthThemePreferenceStore,
        photoLibraryService: PhotoLibraryService,
        growthAnimationService: GrowthAnimationService
    ) {
        self.plant = plant
        self.growthRecordRepository = growthRecordRepository
        self.growthThemePreferenceStore = growthThemePreferenceStore
        self.photoLibraryService = photoLibraryService
        self.growthAnimationService = growthAnimationService
        state.selectedThemeKind = growthThemePreferenceStore.selectedThemeKind()
    }

    var selectedTheme: GrowthTheme {
        GrowthTheme.builtInThemes.first(where: { $0.kind == state.selectedThemeKind }) ?? .default
    }

    func load() {
        state.isLoading = true
        defer { state.isLoading = false }

        do {
            state.growthRecords = try growthRecordRepository.fetchGrowthRecords(plantID: plant.id)
            state.errorMessage = nil
        } catch {
            state.errorMessage = "成长记录加载失败，请稍后重试。"
        }
    }

    func selectTheme(_ kind: GrowthTheme.Kind) {
        state.selectedThemeKind = kind
        growthThemePreferenceStore.setSelectedThemeKind(kind)
    }

    func deleteGrowthRecord(id: UUID) -> Bool {
        do {
            try growthRecordRepository.deleteGrowthRecord(id: id)
            state.growthRecords.removeAll { $0.id == id }
            state.errorMessage = nil
            return true
        } catch {
            state.errorMessage = "删除成长记录失败，请稍后重试。"
            return false
        }
    }

    func exportGrowthAnimation() async -> Bool {
        guard !state.growthRecords.isEmpty else {
            state.errorMessage = "至少需要一条成长记录才能生成动画。"
            return false
        }

        state.isExportingAnimation = true
        state.exportProgress = 0
        state.exportStatusMessage = "正在读取成长照片…"
        defer {
            state.isExportingAnimation = false
            state.exportStatusMessage = nil
        }

        do {
            let orderedAssetIdentifiers = state.growthRecords
                .sorted(by: { $0.recordedAt < $1.recordedAt })
                .map(\.photoAssetIdentifier)

            let frames = try await photoLibraryService.loadCGImages(
                for: orderedAssetIdentifiers,
                targetSize: CGSize(width: 1080, height: 1080),
                progress: { [weak self] progress in
                    Task { @MainActor in
                        guard let self else { return }
                        self.state.exportProgress = progress * 0.35
                    }
                }
            )

            let outputURL = makeExportURL()
            let descriptor = GrowthAnimationDescriptor(
                plantName: plant.displayName,
                recordCount: state.growthRecords.count,
                daysSincePlanted: plant.daysSincePlanted,
                themeKind: state.selectedThemeKind
            )
            let exportedURL = try await growthAnimationService.exportTimelineVideo(
                from: frames,
                outputURL: outputURL,
                descriptor: descriptor,
                progressHandler: { [weak self] progress in
                    Task { @MainActor in
                        guard let self else { return }
                        self.state.exportStatusMessage = "正在合成成长视频…"
                        self.state.exportProgress = 0.35 + (progress * 0.65)
                    }
                }
            )

            state.exportedVideoURL = exportedURL
            state.exportProgress = 1
            state.errorMessage = nil
            return true
        } catch {
            state.errorMessage = error.localizedDescription
            return false
        }
    }

    private func makeExportURL() -> URL {
        let sanitizedName = plant.displayName.replacingOccurrences(of: " ", with: "-")
        let fileName = "growth-\(sanitizedName)-\(UUID().uuidString).mp4"
        return FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
    }
}
