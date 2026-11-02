import Foundation

/// Blank is the fold result when the well has nothing waiting and today is not nailed.
/// A well with stubs on other month-days stays Bare instead.
struct Blank: Codable, Equatable, Sendable, Identifiable {
    var id: UUID
    var dayKey: Int
    var recordedAt: Date
}
