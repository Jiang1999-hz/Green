import Foundation
import UIKit

enum GrowthRecordFormMode: Equatable {
    case create(UUID)
    case edit(UUID)

    var title: String {
        switch self {
        case .create:
            return "新增成长记录"
        case .edit:
            return "编辑成长记录"
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

    var successMessage: String {
        switch self {
        case .create:
            return "成长记录已保存。"
        case .edit:
            return "成长记录已更新。"
        }
    }
}

@MainActor
final class GrowthRecordFormViewModel: ObservableObject {
    @Published var draft: GrowthRecordDraft
    @Published private(set) var isSaving = false
    @Published private(set) var isProcessingPhoto = false
    @Published private(set) var photoPreviewImage: UIImage?
    @Published var errorMessage: String?

    let mode: GrowthRecordFormMode
    let plantID: UUID

    private let growthRecordRepository: any GrowthRecordRepository
    private let photoLibraryService: PhotoLibraryService

    init(
        mode: GrowthRecordFormMode,
        plantID: UUID,
        draft: GrowthRecordDraft = GrowthRecordDraft(),
        growthRecordRepository: any GrowthRecordRepository,
        photoLibraryService: PhotoLibraryService
    ) {
        self.mode = mode
        self.plantID = plantID
        self.draft = draft
        self.growthRecordRepository = growthRecordRepository
        self.photoLibraryService = photoLibraryService
    }

    var isBusy: Bool {
        isSaving || isProcessingPhoto
    }

    var photoValidationMessage: String? {
        draft.photoAssetIdentifier == nil ? "请先添加一张成长照片。" : nil
    }

    func handleSelectedPhoto(
        assetIdentifier: String?,
        previewImage: UIImage?
    ) async {
        isProcessingPhoto = true
        defer { isProcessingPhoto = false }

        let accessState = await photoLibraryService.ensureReadWriteAccess()
        guard accessState == .authorized || accessState == .limited else {
            draft.photoAssetIdentifier = nil
            photoPreviewImage = nil
            errorMessage = "需要允许访问系统相册后才能保存成长照片。"
            return
        }

        if let assetIdentifier, !assetIdentifier.isEmpty {
            draft.photoAssetIdentifier = assetIdentifier
            photoPreviewImage = previewImage
            errorMessage = nil
            return
        }

        guard let previewImage else {
            draft.photoAssetIdentifier = nil
            photoPreviewImage = nil
            errorMessage = "未能读取所选照片，请换一张再试。"
            return
        }

        do {
            let generatedAssetIdentifier = try await photoLibraryService.saveImageToPlantAlbum(previewImage)
            draft.photoAssetIdentifier = generatedAssetIdentifier
            photoPreviewImage = previewImage
            errorMessage = nil
        } catch {
            draft.photoAssetIdentifier = nil
            photoPreviewImage = nil
            errorMessage = error.localizedDescription
        }
    }

    func saveCapturedPhoto(_ image: UIImage) async {
        isProcessingPhoto = true
        defer { isProcessingPhoto = false }

        do {
            let assetIdentifier = try await photoLibraryService.saveImageToPlantAlbum(image)
            draft.photoAssetIdentifier = assetIdentifier
            photoPreviewImage = image
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func removePhoto() {
        draft.photoAssetIdentifier = nil
        photoPreviewImage = nil
    }

    func save() -> Bool {
        errorMessage = nil

        guard validateDraft() else {
            return false
        }

        isSaving = true
        defer { isSaving = false }

        do {
            switch mode {
            case .create:
                _ = try growthRecordRepository.createGrowthRecord(for: plantID, from: draft)
            case let .edit(recordID):
                _ = try growthRecordRepository.updateGrowthRecord(id: recordID, with: draft)
            }
            return true
        } catch {
            errorMessage = "成长记录保存失败，请稍后重试。"
            return false
        }
    }

    private func validateDraft() -> Bool {
        draft.photoAssetIdentifier != nil
    }
}
