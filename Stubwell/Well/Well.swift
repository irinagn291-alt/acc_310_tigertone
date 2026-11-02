import Foundation

/// Well holds anniversary stubs that are waiting for their month and day.
/// A nail lifts one stub out. Peel puts that stub back so the match can run again.
struct Well: Codable, Equatable, Sendable {
    var stubs: [Stub]

    static let empty = Well(stubs: [])

    func waiting(on anniversary: Int) -> [Stub] {
        stubs.filter { $0.anniversary == anniversary }
    }
}
