import Foundation

/// HollowMark records Close on a held volume when no slip was chosen.
/// The volume stays held. Nothing enters the well.
struct HollowMark: Codable, Equatable, Sendable, Identifiable {
    var id: UUID
    var dayKey: Int
    var volumeID: UUID
    var recordedAt: Date
}
