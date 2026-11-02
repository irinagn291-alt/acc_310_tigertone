import Foundation

/// FileMark records a Close that chose a slip.
/// It is the age key when several stubs share one month and day.
struct FileMark: Codable, Equatable, Sendable, Identifiable {
    var id: UUID
    var dayKey: Int
    var volumeID: UUID
    var slipID: UUID
    var recordedAt: Date
}
