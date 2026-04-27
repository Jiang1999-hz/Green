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

    private let originalDraft: PlantDraft
    private let plantRepository: any PlantRepository
    private let photoLibraryService: PhotoLibraryService
    private let wateringReminderService: WateringReminderService

    init(
        mode: PlantFormMode,
        draft: PlantDraft = PlantDraft(),
        plantRepository: any PlantRepository,
        photoLibraryService: PhotoLibraryService,
        wateringReminderService: WateringReminderService
    ) {
        self.mode = mode
        self.draft = draft
        self.originalDraft = draft
        self.plantRepository = plantRepository
        self.photoLibraryService = photoLibraryService
        self.wateringReminderService = wateringReminderService
    }

    var isBusy: Bool {
        isSaving || isProcessingCoverPhoto
    }

    var nameValidationMessage: String? {
        draft.trimmedName.isEmpty ? "请输入植物名称后再保存。" : nil
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
        errorMessage = nil

        guard validateDraft() else {
            return false
        }

        isSaving = true
        defer { isSaving = false }

        do {
            let finalDraft = preparedDraft()
            let savedPlant: PlantRecord

            switch mode {
            case .create:
                savedPlant = try plantRepository.createPlant(from: finalDraft)
            case let .edit(plantID):
                savedPlant = try plantRepository.updatePlant(id: plantID, with: finalDraft)
            }

            Task {
                try? await wateringReminderService.scheduleReminder(for: savedPlant)
            }
            errorMessage = nil
            return true
        } catch {
            errorMessage = "植物档案保存失败，请稍后重试。"
            return false
        }
    }

    private func validateDraft() -> Bool {
        !draft.trimmedName.isEmpty && draft.wateringIntervalDays > 0
    }

    private func preparedDraft() -> PlantDraft {
        var finalDraft = draft
        finalDraft.lastWateredDate = resolvedLastWateredDate(for: finalDraft)
        finalDraft.nextWateringDate = resolvedNextWateringDate(for: finalDraft)
        return finalDraft
    }

    private func resolvedLastWateredDate(for draft: PlantDraft) -> Date? {
        switch mode {
        case .create:
            return draft.lastWateredDate
        case .edit:
            return originalDraft.lastWateredDate
        }
    }

    private func resolvedNextWateringDate(for draft: PlantDraft) -> Date? {
        switch mode {
        case .create:
            return PlantWateringSchedule.nextWateringDate(
                intervalDays: draft.wateringIntervalDays,
                lastWateredDate: draft.lastWateredDate
            )
        case .edit:
            if draft.wateringIntervalDays != originalDraft.wateringIntervalDays {
                return PlantWateringSchedule.nextWateringDate(
                    intervalDays: draft.wateringIntervalDays,
                    lastWateredDate: originalDraft.lastWateredDate
                )
            }

            return originalDraft.nextWateringDate
        }
    }
}
