import Foundation

/// Volume is the book in the stub fold.
/// Held keeps one quote-store of slips, a yes or no reread verdict, and a live
/// progress fraction. Closed freezes that fraction and accepts no new slip.
struct Volume: Codable, Equatable, Sendable, Identifiable {
    enum Stance: String, Codable, Sendable {
        case held
        case closed
    }

    var id: UUID
    var title: String
    var author: String
    var totalPages: Int
    var currentPage: Int
    var stance: Stance
    var reread: Bool
    var slips: [Slip]
    /// Captured at Close. Nil while the volume is still held.
    var frozenFraction: Double?

    /// Held: current page divided by total pages. Closed: the frozen fraction.
    var progressFraction: Double {
        if stance == .closed, let frozenFraction {
            return frozenFraction
        }
        guard totalPages > 0 else { return 0 }
        let page = min(max(currentPage, 0), totalPages)
        return Double(page) / Double(totalPages)
    }

    var isHeld: Bool { stance == .held }
}
