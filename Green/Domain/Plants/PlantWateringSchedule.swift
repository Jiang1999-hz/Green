import Foundation

enum PlantWateringSchedule {
    static func nextWateringDate(
        intervalDays: Int,
        lastWateredDate: Date?,
        fallbackDate: Date = .now
    ) -> Date {
        let baseDate = lastWateredDate ?? fallbackDate
        return Calendar.current.date(
            byAdding: .day,
            value: max(intervalDays, 1),
            to: baseDate
        ) ?? baseDate
    }
}
