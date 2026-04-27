import AVFoundation
import CoreGraphics
import CoreVideo
import Foundation
import UIKit

enum GrowthAnimationError: LocalizedError {
    case noFrames
    case writerUnavailable
    case pixelBufferPoolUnavailable
    case appendFailed
    case exportFailed

    var errorDescription: String? {
        switch self {
        case .noFrames:
            return "当前没有可用于生成动画的成长照片。"
        case .writerUnavailable:
            return "动画导出初始化失败。"
        case .pixelBufferPoolUnavailable:
            return "动画帧缓存初始化失败。"
        case .appendFailed:
            return "动画帧写入失败。"
        case .exportFailed:
            return "成长动画导出失败，请稍后重试。"
        }
    }
}

final class GrowthAnimationService {
    private let exportQueue = DispatchQueue(label: "green.growth-animation.export", qos: .userInitiated)

    private enum ExportDefaults {
        static let framesPerSecond: Int32 = 12
        static let stillDuration: TimeInterval = 0.9
        static let transitionDuration: TimeInterval = 0.3
        static let maxZoomScale: CGFloat = 1.06
    }

    func exportTimelineVideo(
        from frames: [CGImage],
        outputURL: URL,
        descriptor: GrowthAnimationDescriptor,
        renderSize: CGSize = CGSize(width: 1080, height: 1080),
        progressHandler: ((Double) -> Void)? = nil
    ) async throws -> URL {
        let exportQueue = self.exportQueue
        return try await withCheckedThrowingContinuation { continuation in
            exportQueue.async {
                do {
                    let exportedURL = try Self.exportVideoSynchronously(
                        from: frames,
                        outputURL: outputURL,
                        descriptor: descriptor,
                        renderSize: renderSize,
                        progressHandler: progressHandler
                    )
                    continuation.resume(returning: exportedURL)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private static func exportVideoSynchronously(
        from frames: [CGImage],
        outputURL: URL,
        descriptor: GrowthAnimationDescriptor,
        renderSize: CGSize,
        progressHandler: ((Double) -> Void)?
    ) throws -> URL {
        guard !frames.isEmpty else {
            throw GrowthAnimationError.noFrames
        }

        if FileManager.default.fileExists(atPath: outputURL.path) {
            try? FileManager.default.removeItem(at: outputURL)
        }

        let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
        let settings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: Int(renderSize.width),
            AVVideoHeightKey: Int(renderSize.height)
        ]

        let input = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
        input.expectsMediaDataInRealTime = false

        let attributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32ARGB),
            kCVPixelBufferWidthKey as String: Int(renderSize.width),
            kCVPixelBufferHeightKey as String: Int(renderSize.height),
            kCVPixelFormatOpenGLESCompatibility as String: true
        ]

        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: input,
            sourcePixelBufferAttributes: attributes
        )

        guard writer.canAdd(input) else {
            throw GrowthAnimationError.writerUnavailable
        }

        writer.add(input)
        guard writer.startWriting() else {
            throw writer.error ?? GrowthAnimationError.writerUnavailable
        }

        writer.startSession(atSourceTime: .zero)

        guard let pixelBufferPool = adaptor.pixelBufferPool else {
            throw GrowthAnimationError.pixelBufferPoolUnavailable
        }

        let framesPerSecond = ExportDefaults.framesPerSecond
        let holdFrames = max(Int(ExportDefaults.stillDuration * Double(framesPerSecond)), 1)
        let transitionFrames = max(Int(ExportDefaults.transitionDuration * Double(framesPerSecond)), 1)
        var frameIndex: Int64 = 0
        let contentBackgroundColor = contentBackgroundColor(for: descriptor.themeKind)
        let allFrames = try composeFrames(
            contentFrames: frames,
            descriptor: descriptor,
            renderSize: renderSize
        )
        let totalAppendOperations = max(
            allFrames.count * holdFrames + max(allFrames.count - 1, 0) * transitionFrames,
            1
        )
        var completedAppendOperations = 0

        for (index, frame) in allFrames.enumerated() {
            let totalFramesForImage = holdFrames + (index < allFrames.count - 1 ? transitionFrames : 0)

            for holdFrame in 0..<holdFrames {
                while !input.isReadyForMoreMediaData {
                    Thread.sleep(forTimeInterval: 0.01)
                }

                let currentImageProgress = CGFloat(holdFrame) / CGFloat(max(totalFramesForImage - 1, 1))

                guard let pixelBuffer = makePixelBuffer(
                    currentImage: frame.image,
                    nextImage: nil,
                    transitionProgress: 0,
                    currentImageProgress: currentImageProgress,
                    nextImageProgress: 0,
                    backgroundColor: contentBackgroundColor,
                    size: renderSize,
                    pixelBufferPool: pixelBufferPool
                ) else {
                    throw GrowthAnimationError.appendFailed
                }

                let presentationTime = CMTime(value: frameIndex, timescale: framesPerSecond)
                guard adaptor.append(pixelBuffer, withPresentationTime: presentationTime) else {
                    throw writer.error ?? GrowthAnimationError.appendFailed
                }

                frameIndex += 1
                completedAppendOperations += 1
                progressHandler?(Double(completedAppendOperations) / Double(totalAppendOperations))
            }

            guard index < allFrames.count - 1 else {
                continue
            }

            let nextImage = allFrames[index + 1].image
            for transitionFrame in 0..<transitionFrames {
                while !input.isReadyForMoreMediaData {
                    Thread.sleep(forTimeInterval: 0.01)
                }

                let transitionProgress = CGFloat(transitionFrame + 1) / CGFloat(transitionFrames + 1)
                let currentImageProgress = CGFloat(holdFrames + transitionFrame + 1) / CGFloat(totalFramesForImage)
                let nextImageProgress = CGFloat(transitionFrame + 1) / CGFloat(holdFrames + transitionFrames)
                guard let pixelBuffer = makePixelBuffer(
                    currentImage: frame.image,
                    nextImage: nextImage,
                    transitionProgress: transitionProgress,
                    currentImageProgress: currentImageProgress,
                    nextImageProgress: nextImageProgress,
                    backgroundColor: contentBackgroundColor,
                    size: renderSize,
                    pixelBufferPool: pixelBufferPool
                ) else {
                    throw GrowthAnimationError.appendFailed
                }

                let presentationTime = CMTime(value: frameIndex, timescale: framesPerSecond)
                guard adaptor.append(pixelBuffer, withPresentationTime: presentationTime) else {
                    throw writer.error ?? GrowthAnimationError.appendFailed
                }

                frameIndex += 1
                completedAppendOperations += 1
                progressHandler?(Double(completedAppendOperations) / Double(totalAppendOperations))
            }
        }

        input.markAsFinished()

        return try finishWriting(writer, outputURL: outputURL)
    }

    private static func composeFrames(
        contentFrames: [CGImage],
        descriptor: GrowthAnimationDescriptor,
        renderSize: CGSize
    ) throws -> [ExportFrame] {
        let intro = try makeInfoFrame(
            title: descriptor.introTitle,
            subtitle: descriptor.introSubtitle,
            detail: descriptor.introDetail,
            themeKind: descriptor.themeKind,
            renderSize: renderSize,
            isClosing: false
        )
        let outro = try makeInfoFrame(
            title: descriptor.outroTitle,
            subtitle: descriptor.outroSubtitle,
            detail: descriptor.outroDetail,
            themeKind: descriptor.themeKind,
            renderSize: renderSize,
            isClosing: true
        )

        return [ExportFrame(image: intro)] +
            contentFrames.map { ExportFrame(image: $0) } +
            [ExportFrame(image: outro)]
    }

    private static func makeInfoFrame(
        title: String,
        subtitle: String,
        detail: String,
        themeKind: GrowthTheme.Kind,
        renderSize: CGSize,
        isClosing: Bool
    ) throws -> CGImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: renderSize, format: format)

        let image = renderer.image { context in
            let cgContext = context.cgContext

            let style = themeStyle(for: themeKind, isClosing: isClosing)

            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let locations: [CGFloat] = [0, 1]
            let cgColors = style.backgroundColors.map(\.cgColor) as CFArray
            let gradient = CGGradient(colorsSpace: colorSpace, colors: cgColors, locations: locations)
            cgContext.drawLinearGradient(
                gradient!,
                start: CGPoint(x: 0, y: 0),
                end: CGPoint(x: renderSize.width, y: renderSize.height),
                options: []
            )

            let cardRect = CGRect(
                x: 84,
                y: 180,
                width: renderSize.width - 168,
                height: renderSize.height - 360
            )

            let cardPath = UIBezierPath(roundedRect: cardRect, cornerRadius: 42)
            style.cardFillColor.setFill()
            cardPath.fill()

            let centeredParagraph = NSMutableParagraphStyle()
            centeredParagraph.alignment = .center

            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 72, weight: .bold),
                .foregroundColor: style.titleColor,
                .paragraphStyle: centeredParagraph
            ]
            let subtitleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 36, weight: .semibold),
                .foregroundColor: style.subtitleColor,
                .paragraphStyle: centeredParagraph
            ]
            let detailAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 30, weight: .medium),
                .foregroundColor: style.detailColor,
                .paragraphStyle: centeredParagraph
            ]

            let titleRect = CGRect(x: 128, y: 330, width: renderSize.width - 256, height: 180)
            let subtitleRect = CGRect(x: 128, y: 520, width: renderSize.width - 256, height: 70)
            let detailRect = CGRect(x: 128, y: 640, width: renderSize.width - 256, height: 120)

            title.draw(in: titleRect, withAttributes: titleAttributes)
            subtitle.draw(in: subtitleRect, withAttributes: subtitleAttributes)
            detail.draw(in: detailRect, withAttributes: detailAttributes)
        }

        guard let cgImage = image.cgImage else {
            throw GrowthAnimationError.exportFailed
        }

        return cgImage
    }

    private struct ExportFrame {
        let image: CGImage
    }

    private static func themeStyle(
        for themeKind: GrowthTheme.Kind,
        isClosing: Bool
    ) -> ExportThemeStyle {
        switch (themeKind, isClosing) {
        case (.defaultGarden, false):
            return ExportThemeStyle(
                backgroundColors: [
                    UIColor(red: 0.10, green: 0.18, blue: 0.12, alpha: 1),
                    UIColor(red: 0.31, green: 0.55, blue: 0.34, alpha: 1)
                ],
                cardFillColor: UIColor.white.withAlphaComponent(0.12),
                titleColor: .white,
                subtitleColor: UIColor.white.withAlphaComponent(0.82),
                detailColor: UIColor.white.withAlphaComponent(0.76)
            )
        case (.defaultGarden, true):
            return ExportThemeStyle(
                backgroundColors: [
                    UIColor(red: 0.94, green: 0.98, blue: 0.93, alpha: 1),
                    UIColor(red: 0.82, green: 0.91, blue: 0.78, alpha: 1)
                ],
                cardFillColor: UIColor.white.withAlphaComponent(0.72),
                titleColor: UIColor(red: 0.13, green: 0.20, blue: 0.13, alpha: 1),
                subtitleColor: UIColor(red: 0.22, green: 0.37, blue: 0.22, alpha: 1),
                detailColor: UIColor(red: 0.22, green: 0.37, blue: 0.22, alpha: 1)
            )
        case (.bloomGlow, false):
            return ExportThemeStyle(
                backgroundColors: [
                    UIColor(red: 0.98, green: 0.72, blue: 0.60, alpha: 1),
                    UIColor(red: 0.98, green: 0.88, blue: 0.76, alpha: 1)
                ],
                cardFillColor: UIColor.white.withAlphaComponent(0.22),
                titleColor: UIColor.white,
                subtitleColor: UIColor.white.withAlphaComponent(0.88),
                detailColor: UIColor.white.withAlphaComponent(0.82)
            )
        case (.bloomGlow, true):
            return ExportThemeStyle(
                backgroundColors: [
                    UIColor(red: 1.00, green: 0.97, blue: 0.93, alpha: 1),
                    UIColor(red: 0.98, green: 0.87, blue: 0.76, alpha: 1)
                ],
                cardFillColor: UIColor.white.withAlphaComponent(0.78),
                titleColor: UIColor(red: 0.44, green: 0.26, blue: 0.19, alpha: 1),
                subtitleColor: UIColor(red: 0.55, green: 0.36, blue: 0.25, alpha: 1),
                detailColor: UIColor(red: 0.55, green: 0.36, blue: 0.25, alpha: 1)
            )
        }
    }

    private struct ExportThemeStyle {
        let backgroundColors: [UIColor]
        let cardFillColor: UIColor
        let titleColor: UIColor
        let subtitleColor: UIColor
        let detailColor: UIColor
    }

    private static func contentBackgroundColor(for themeKind: GrowthTheme.Kind) -> UIColor {
        switch themeKind {
        case .defaultGarden:
            return UIColor(red: 0.97, green: 0.99, blue: 0.96, alpha: 1)
        case .bloomGlow:
            return UIColor(red: 1.00, green: 0.97, blue: 0.94, alpha: 1)
        }
    }

    private static func makePixelBuffer(
        currentImage: CGImage,
        nextImage: CGImage?,
        transitionProgress: CGFloat,
        currentImageProgress: CGFloat,
        nextImageProgress: CGFloat,
        backgroundColor: UIColor,
        size: CGSize,
        pixelBufferPool: CVPixelBufferPool
    ) -> CVPixelBuffer? {
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferPoolCreatePixelBuffer(nil, pixelBufferPool, &pixelBuffer)
        guard status == kCVReturnSuccess, let pixelBuffer else {
            return nil
        }

        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, []) }

        guard
            let context = CGContext(
                data: CVPixelBufferGetBaseAddress(pixelBuffer),
                width: Int(size.width),
                height: Int(size.height),
                bitsPerComponent: 8,
                bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
            )
        else {
            return nil
        }

        context.setFillColor(backgroundColor.cgColor)
        context.fill(CGRect(origin: .zero, size: size))

        let currentRect = fittedRect(
            for: CGSize(width: currentImage.width, height: currentImage.height),
            in: size,
            progress: currentImageProgress
        )
        context.saveGState()
        context.setAlpha(1 - transitionProgress)
        context.draw(currentImage, in: currentRect)
        context.restoreGState()

        if let nextImage {
            let nextRect = fittedRect(
                for: CGSize(width: nextImage.width, height: nextImage.height),
                in: size,
                progress: nextImageProgress
            )
            context.saveGState()
            context.setAlpha(transitionProgress)
            context.draw(nextImage, in: nextRect)
            context.restoreGState()
        }

        return pixelBuffer
    }

    private static func fittedRect(
        for imageSize: CGSize,
        in renderSize: CGSize,
        progress: CGFloat
    ) -> CGRect {
        let widthScale = renderSize.width / imageSize.width
        let heightScale = renderSize.height / imageSize.height
        let scale = min(widthScale, heightScale)
        let zoomScale = 1 + ((ExportDefaults.maxZoomScale - 1) * progress)

        let fittedSize = CGSize(
            width: imageSize.width * scale * zoomScale,
            height: imageSize.height * scale * zoomScale
        )

        let origin = CGPoint(
            x: (renderSize.width - fittedSize.width) / 2,
            y: (renderSize.height - fittedSize.height) / 2
        )

        return CGRect(origin: origin, size: fittedSize)
    }

    private static func finishWriting(_ writer: AVAssetWriter, outputURL: URL) throws -> URL {
        let semaphore = DispatchSemaphore(value: 0)
        var finishError: Error?

        writer.finishWriting {
            finishError = writer.error
            semaphore.signal()
        }

        semaphore.wait()

        if let finishError {
            throw finishError
        }

        guard writer.status == .completed else {
            throw writer.error ?? GrowthAnimationError.exportFailed
        }

        return outputURL
    }
}
