import Foundation

/// NailMark records a Nail that seated a due stub's slip on that day key.
/// A second nail on the same day key is refused until Peel drops this mark.
struct NailMark: Codable, Equatable, Sendable, Identifiable {
    var id: UUID
    var dayKey: Int
    var stubID: UUID
    var slipID: UUID
    var recordedAt: Date
}
