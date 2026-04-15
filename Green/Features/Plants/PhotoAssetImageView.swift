import Photos
import SwiftUI
import UIKit

struct PhotoAssetImageView: View {
    let assetIdentifier: String?
    let size: CGSize
    let cornerRadius: CGFloat
    let placeholderSystemImage: String

    @State private var image: UIImage?

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(AppTheme.primary.opacity(0.12))
                    .overlay {
                        Image(systemName: placeholderSystemImage)
                            .font(.system(size: min(size.width, size.height) * 0.34, weight: .medium))
                            .foregroundStyle(AppTheme.primary)
                    }
            }
        }
        .frame(width: size.width, height: size.height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .task(id: assetIdentifier) {
            await loadImage()
        }
    }

    @MainActor
    private func loadImage() async {
        guard let assetIdentifier, !assetIdentifier.isEmpty else {
            image = nil
            return
        }

        let authorizationStatus = await ensureReadAccess()
        guard authorizationStatus == .authorized || authorizationStatus == .limited else {
            image = nil
            return
        }

        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [assetIdentifier], options: nil)
        guard let asset = assets.firstObject else {
            image = nil
            return
        }

        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat

        image = await withCheckedContinuation { continuation in
            PHImageManager.default().requestImageDataAndOrientation(for: asset, options: options) { data, _, _, _ in
                continuation.resume(returning: data.flatMap { UIImage(data: $0) })
            }
        }
    }

    private func ensureReadAccess() async -> PHAuthorizationStatus {
        let current = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        guard current == .notDetermined else {
            return current
        }

        return await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                continuation.resume(returning: status)
            }
        }
    }
}
