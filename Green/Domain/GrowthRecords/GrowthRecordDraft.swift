import Foundation

struct GrowthRecordDraft: Equatable, Sendable {
    var recordedAt: Date
    var note: String
    var photoAssetIdentifier: String?

    init(
        recordedAt: Date = .now,
        note: String = "",
        photoAssetIdentifier: String? = nil
    ) {
        self.recordedAt = recordedAt
        self.note = note
        self.photoAssetIdentifier = photoAssetIdentifier
    }

    var normalizedNote: String? {
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
