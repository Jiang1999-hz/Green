import Foundation

struct GrowthRecordEntry: Identifiable, Equatable, Sendable {
    let id: UUID
    let plantID: UUID
    let recordedAt: Date
    let note: String?
    let photoAssetIdentifier: String
    let heightCM: Double?
    let healthStatusRaw: String?
    let visionSummary: String?
    let createdAt: Date

    var recordedDateLabel: String {
        recordedAt.formatted(date: .abbreviated, time: .omitted)
    }

    var recordedTimestampLabel: String {
        recordedAt.formatted(date: .abbreviated, time: .shortened)
    }

    var displayNote: String {
        guard let note, !note.isEmpty else {
            return "还没有补充本次成长记录。"
        }

        return note
    }
}
