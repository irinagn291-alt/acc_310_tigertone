import Foundation

/// Stub is an anniversary filing. Its key is the close date's month and day
/// (day key modulo 10000). It points at a slip. It does not copy the line.
struct Stub: Codable, Equatable, Sendable, Identifiable {
    var id: UUID
    var volumeID: UUID
    var slipID: UUID
    var anniversary: Int
    var fileMarkID: UUID
}
