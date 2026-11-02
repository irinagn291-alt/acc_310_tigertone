import Foundation

/// Board is one day key in the fold. Phases are Bare, Due, and Nailed.
/// Due names the oldest waiting stub. Nailed holds that stub out of the well
/// and seats its slip by identity.
struct Board: Codable, Equatable, Sendable, Identifiable {
    enum Phase: String, Codable, Sendable {
        case bare
        case due
        case nailed
    }

    var dayKey: Int
    var phase: Phase
    var dueStubID: UUID?
    var seatedSlipID: UUID?
    /// The stub lifted out of the well while this day key is nailed.
    var lifted: Stub?

    var id: Int { dayKey }
}

/// BoardFace is the projection the quotes surface reads.
/// The line is resolved from the volume quote-store. It is not a second copy stored on the board.
struct BoardFace: Equatable, Sendable {
    enum Fold: String, Equatable, Sendable {
        case blank
        case bare
        case due
        case nailed
    }

    var fold: Fold
    var dayKey: Int
    var anniversary: Int
    var stubID: UUID?
    var volumeID: UUID?
    var slipID: UUID?
    var line: String
    var page: Int?
    var nailEnabled: Bool
    var peelEnabled: Bool

    static func blank(dayKey: Int) -> BoardFace {
        BoardFace(
            fold: .blank,
            dayKey: dayKey,
            anniversary: DayStamp.anniversary(dayKey),
            stubID: nil,
            volumeID: nil,
            slipID: nil,
            line: "",
            page: nil,
            nailEnabled: false,
            peelEnabled: false
        )
    }
}
