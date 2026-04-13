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

struct PhotoLibraryService {
    func authorizationState(for accessLevel: PHAccessLevel = .readWrite) -> PhotoLibraryAccessState {
        map(PHPhotoLibrary.authorizationStatus(for: accessLevel))
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
}
