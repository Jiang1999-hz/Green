import Foundation

struct PlantRecord: Identifiable, Equatable, Sendable {
    let id: UUID
    let name: String
    let species: String?
    let location: String?
    let plantedDate: Date
    let wateringIntervalDays: Int
    let lastWateredDate: Date?
    let nextWateringDate: Date?
    let notes: String?
    let coverPhotoAssetIdentifier: String?
    let createdAt: Date
    let updatedAt: Date

    var displayName: String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "未命名植物" : trimmed
    }

    var displayLocation: String {
        guard let location, !location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return "位置待补充"
        }

        return location
    }

    var displaySpecies: String {
        guard let species, !species.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return "种类待补充"
        }

        return species
    }

    var daysSincePlanted: Int {
        max(Calendar.current.dateComponents([.day], from: plantedDate, to: .now).day ?? 0, 0)
    }

    var nextWateringLabel: String {
        guard let nextWateringDate else {
            return "提醒待接入"
        }

        return "下次 \(nextWateringDate.formatted(date: .numeric, time: .omitted))"
    }

    var lastWateredLabel: String {
        guard let lastWateredDate else {
            return "还没有记录"
        }

        if Calendar.current.isDateInToday(lastWateredDate) {
            return "今天"
        }

        return lastWateredDate.formatted(date: .abbreviated, time: .omitted)
    }

    var isWateredToday: Bool {
        guard let lastWateredDate else {
            return false
        }

        return Calendar.current.isDateInToday(lastWateredDate)
    }

    var plantedDateLabel: String {
        plantedDate.formatted(date: .abbreviated, time: .omitted)
    }

    var wateringIntervalLabel: String {
        "每 \(wateringIntervalDays) 天浇水"
    }

    var isWateringDueToday: Bool {
        guard let nextWateringDate else {
            return false
        }

        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: .now)
        let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: startOfToday) ?? .now
        return nextWateringDate < startOfTomorrow
    }

    var wateringStatusLabel: String {
        if isWateredToday {
            return "今日已浇水"
        }

        guard let nextWateringDate else {
            return "提醒待接入"
        }

        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: .now)
        let startOfTargetDay = calendar.startOfDay(for: nextWateringDate)
        let dayOffset = calendar.dateComponents([.day], from: startOfToday, to: startOfTargetDay).day ?? 0

        if dayOffset <= 0 {
            return "今日需浇水"
        }

        return "\(dayOffset) 天后浇水"
    }
}
