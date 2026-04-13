import AVFoundation
import CoreGraphics
import Foundation

enum GrowthAnimationError: Error {
    case noFrames
    case notImplementedYet
}

final class GrowthAnimationService {
    private let exportQueue = DispatchQueue.global(qos: .userInitiated)

    // Export work stays off the main queue so later AVFoundation composition won't block UI rendering.
    func exportTimelineVideo(
        from frames: [CGImage],
        outputURL: URL,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        exportQueue.async {
            guard !frames.isEmpty else {
                completion(.failure(GrowthAnimationError.noFrames))
                return
            }

            _ = outputURL
            completion(.failure(GrowthAnimationError.notImplementedYet))
        }
    }
}
