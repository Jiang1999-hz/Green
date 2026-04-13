import CoreImage
import Vision

struct PlantHealthSnapshot {
    let summary: String
    let confidence: Double
}

enum PlantHealthAnalysisError: Error {
    case notImplementedYet
}

final class PlantHealthAnalysisService {
    func analyze(ciImage: CIImage) async throws -> PlantHealthSnapshot {
        _ = ciImage
        throw PlantHealthAnalysisError.notImplementedYet
    }
}
