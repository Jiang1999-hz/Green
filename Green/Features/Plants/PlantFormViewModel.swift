import Foundation
import UIKit

enum PlantFormMode: Equatable {
    case create
    case edit(UUID)

    var title: String {
        switch self {
        case .create:
            return "添加植物"
        case .edit:
            return "编辑植物"
        }
    }

    var saveButtonTitle: String {
        switch self {
        case .create:
            return "保存"
        case .edit:
            return "更新"
        }
    }
}

@MainActor
final class PlantFormViewModel: ObservableObject {
    @Published var draft: PlantDraft
    @Published private(set) var isSaving = false
    @Published private(set) var isProcessingCoverPhoto = false
    @Published private(set) var coverPhotoPreviewImage: UIImage?
    @Published var errorMessage: String?

    let mode: PlantFormMode

    private let plantRepository: any PlantRepository
    private let photoLibraryService: PhotoLibraryService

    init(
        mode: PlantFormMode,
        draft: PlantDraft = PlantDraft(),
        plantRepository: any PlantRepository,
        photoLibraryService: PhotoLibraryService
    ) {
        self.mode = mode
        self.draft = draft
        self.plantRepository = plantRepository
        self.photoLibraryService = photoLibraryService
    }

    var isBusy: Bool {
        isSaving || isProcessingCoverPhoto
    }

    func handleSelectedCoverPhoto(
        assetIdentifier: String?,
        previewImage: UIImage?
    ) async {
        isProcessingCoverPhoto = true
        defer { isProcessingCoverPhoto = false }

        let accessState = await photoLibraryService.ensureReadWriteAccess()
        guard accessState == .authorized || accessState == .limited else {
            draft.coverPhotoAssetIdentifier = nil
            coverPhotoPreviewImage = nil
            errorMessage = "需要允许访问系统相册后才能保存封面照片。"
            return
        }

        if let assetIdentifier, !assetIdentifier.isEmpty {
            draft.coverPhotoAssetIdentifier = assetIdentifier
            coverPhotoPreviewImage = previewImage
            errorMessage = nil
            return
        }

        guard let previewImage else {
            draft.coverPhotoAssetIdentifier = nil
            coverPhotoPreviewImage = nil
            errorMessage = "未能读取所选照片，请换一张再试。"
            return
        }

        do {
            let generatedAssetIdentifier = try await photoLibraryService.saveImageToPlantAlbum(previewImage)
            draft.coverPhotoAssetIdentifier = generatedAssetIdentifier
            coverPhotoPreviewImage = previewImage
            errorMessage = nil
        } catch {
            draft.coverPhotoAssetIdentifier = nil
            coverPhotoPreviewImage = nil
            errorMessage = error.localizedDescription
        }
    }

    func removeCoverPhoto() {
        draft.coverPhotoAssetIdentifier = nil
        coverPhotoPreviewImage = nil
    }

    func saveCapturedCoverPhoto(_ image: UIImage) async {
        isProcessingCoverPhoto = true
        defer { isProcessingCoverPhoto = false }

        do {
            let assetIdentifier = try await photoLibraryService.saveImageToPlantAlbum(image)
            draft.coverPhotoAssetIdentifier = assetIdentifier
            coverPhotoPreviewImage = image
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func save() -> Bool {
        guard validateDraft() else {
            return false
        }

        isSaving = true
        defer { isSaving = false }

        do {
            let finalDraft = preparedDraft()

            switch mode {
            case .create:
                _ = try plantRepository.createPlant(from: finalDraft)
            case let .edit(plantID):
                _ = try plantRepository.updatePlant(id: plantID, with: finalDraft)
            }

            errorMessage = nil
            return true
        } catch {
            errorMessage = "植物档案保存失败，请稍后重试。"
            return false
        }
    }

    private func validateDraft() -> Bool {
        guard !draft.trimmedName.isEmpty else {
            errorMessage = "请输入植物名称。"
            return false
        }

        guard draft.wateringIntervalDays > 0 else {
            errorMessage = "浇水频率至少为 1 天。"
            return false
        }

        return true
    }

    private func preparedDraft() -> PlantDraft {
        var finalDraft = draft
        finalDraft.nextWateringDate = Calendar.current.date(
            byAdding: .day,
            value: max(finalDraft.wateringIntervalDays, 1),
            to: .now
        )
        return finalDraft
    }
}
