import Foundation

/// Day key is YYYYMMDD from the start of the civil day.
/// The stub anniversary is that integer modulo 10000 (month and day).
enum DayStamp {
    static func dayKey(_ date: Date, calendar: Calendar) -> Int {
        let start = calendar.startOfDay(for: date)
        let parts = calendar.dateComponents([.year, .month, .day], from: start)
        let year = parts.year ?? 0
        let month = parts.month ?? 0
        let day = parts.day ?? 0
        return year * 10_000 + month * 100 + day
    }

    static func anniversary(_ dayKey: Int) -> Int {
        dayKey % 10_000
    }
}
