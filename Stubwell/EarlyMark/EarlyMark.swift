import Foundation

/// EarlyMark records Nail while the board is still Bare.
/// The board stays Bare. The well is unchanged.
struct EarlyMark: Codable, Equatable, Sendable, Identifiable {
    var id: UUID
    var dayKey: Int
    var recordedAt: Date
}
