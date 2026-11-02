import Foundation

/// Result of a mark. Refusals name the transition the fold rejected.
enum DeskEffect: Equatable, Sendable {
    case filed(FileMark)
    case nailed(NailMark)
    case early(EarlyMark)
    case hollow(HollowMark)
    case peeled(Peel)
    case blank(Blank)
    case refused(Refusal)

    enum Refusal: String, Equatable, Sendable, Error {
        case notHeld
        case alreadyClosed
        case slipMissing
        case alreadyNailed
        case notNailed
        case notDue
        case pageOutOfRange
        case emptyLine
        case missingVolume
    }
}
