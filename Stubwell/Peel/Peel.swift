import Foundation

/// Peel drops the nail mark for a day key, returns the lifted stub to the well,
/// and lets the match pass fold the board again.
struct Peel: Codable, Equatable, Sendable, Identifiable {
    var id: UUID
    var dayKey: Int
    var stubID: UUID
    var droppedNailID: UUID
    var recordedAt: Date
}
