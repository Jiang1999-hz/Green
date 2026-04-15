import Photos
import PhotosUI
import UIKit

enum PhotoLibraryAccessState: Equatable {
    case notDetermined
    case restricted
    case denied
    case limited
    case authorized
}

enum PhotoLibraryServiceError: LocalizedError {
    case permissionDenied
    case assetCreationFailed
    case assetNotFound

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "未获得访问系统相册的权限。"
        case .assetCreationFailed:
            return "照片保存失败，请稍后重试。"
        case .assetNotFound:
            return "找不到刚刚保存的照片资源。"
        }
    }
}

struct PhotoLibraryService {
    func authorizationState(for accessLevel: PHAccessLevel = .readWrite) -> PhotoLibraryAccessState {
        map(PHPhotoLibrary.authorizationStatus(for: accessLevel))
    }

    func ensureReadWriteAccess() async -> PhotoLibraryAccessState {
        let current = authorizationState(for: .readWrite)
        guard current == .notDetermined else {
            return current
        }

        return await requestReadWriteAccess()
    }

    func requestReadWriteAccess() async -> PhotoLibraryAccessState {
        await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                continuation.resume(returning: map(status))
            }
        }
    }

    func requestAddOnlyAccess() async -> PhotoLibraryAccessState {
        await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                continuation.resume(returning: map(status))
            }
        }
    }

    var canReadSelectedPhotos: Bool {
        let status = authorizationState(for: .readWrite)
        return status == .authorized || status == .limited
    }

    func presentLimitedLibraryPicker(from viewController: UIViewController) {
        PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: viewController)
    }

    func saveImageToPlantAlbum(_ image: UIImage, albumName: String = "植物成长") async throws -> String {
        let accessState = await ensureReadWriteAccess()
        guard accessState == .authorized || accessState == .limited else {
            throw PhotoLibraryServiceError.permissionDenied
        }

        let assetIdentifier = try await createAsset(from: image)

        do {
            let album = try await fetchOrCreateAlbum(named: albumName)
            try await addAsset(withIdentifier: assetIdentifier, to: album)
        } catch {
            // The image itself is already saved. Failing to add it to the custom album
            // should not block the plant archive flow.
        }

        return assetIdentifier
    }

    private func map(_ status: PHAuthorizationStatus) -> PhotoLibraryAccessState {
        switch status {
        case .notDetermined:
            return .notDetermined
        case .restricted:
            return .restricted
        case .denied:
            return .denied
        case .limited:
            return .limited
        case .authorized:
            return .authorized
        @unknown default:
            return .denied
        }
    }

    private func createAsset(from image: UIImage) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            var assetIdentifier: String?

            PHPhotoLibrary.shared().performChanges({
                let creationRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
                assetIdentifier = creationRequest.placeholderForCreatedAsset?.localIdentifier
            }) { success, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if success, let assetIdentifier {
                    continuation.resume(returning: assetIdentifier)
                } else {
                    continuation.resume(throwing: PhotoLibraryServiceError.assetCreationFailed)
                }
            }
        }
    }

    private func fetchOrCreateAlbum(named albumName: String) async throws -> PHAssetCollection {
        if let existingAlbum = fetchAlbum(named: albumName) {
            return existingAlbum
        }

        let albumIdentifier: String = try await withCheckedThrowingContinuation { continuation in
            var placeholderIdentifier: String?

            PHPhotoLibrary.shared().performChanges({
                let request = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: albumName)
                placeholderIdentifier = request.placeholderForCreatedAssetCollection.localIdentifier
            }) { success, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if success, let placeholderIdentifier {
                    continuation.resume(returning: placeholderIdentifier)
                } else {
                    continuation.resume(throwing: PhotoLibraryServiceError.assetCreationFailed)
                }
            }
        }

        let collections = PHAssetCollection.fetchAssetCollections(
            withLocalIdentifiers: [albumIdentifier],
            options: nil
        )

        guard let album = collections.firstObject else {
            throw PhotoLibraryServiceError.assetNotFound
        }

        return album
    }

    private func addAsset(withIdentifier assetIdentifier: String, to album: PHAssetCollection) async throws {
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [assetIdentifier], options: nil)

        guard let asset = assets.firstObject else {
            throw PhotoLibraryServiceError.assetNotFound
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            PHPhotoLibrary.shared().performChanges({
                let request = PHAssetCollectionChangeRequest(for: album)
                request?.addAssets([asset] as NSArray)
            }) { success, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if success {
                    continuation.resume(returning: ())
                } else {
                    continuation.resume(throwing: PhotoLibraryServiceError.assetCreationFailed)
                }
            }
        }
    }

    private func fetchAlbum(named albumName: String) -> PHAssetCollection? {
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "localizedTitle == %@", albumName)

        let collections = PHAssetCollection.fetchAssetCollections(
            with: .album,
            subtype: .albumRegular,
            options: options
        )

        return collections.firstObject
    }
}
