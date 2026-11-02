import Foundation

/// Slip is one line in a volume's single quote-store, pinned to a page.
/// The board seats a slip by identity. The words stay on the volume.
struct Slip: Codable, Equatable, Sendable, Identifiable {
    var id: UUID
    var text: String
    var page: Int
}
