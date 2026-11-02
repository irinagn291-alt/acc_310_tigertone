import Foundation

/// StubArchive is the one root record.
/// It holds volumes, each volume's quote-store, the well, day-key boards,
/// and the file, nail, early, and hollow marks. The in-memory value is the
/// source of truth. The store projects it under swl.board.v1.
struct StubArchive: Equatable, Sendable {
    static let schema = 1
    static let defaultsKey = "swl.board.v1"
    static let demoKey = "swl.demo.v1"

    var schemaVersion: Int
    var onboardingComplete: Bool
    var volumes: [Volume]
    var well: Well
    var boards: [Board]
    var fileMarks: [FileMark]
    var nailMarks: [NailMark]
    var earlyMarks: [EarlyMark]
    var hollowMarks: [HollowMark]
    var peels: [Peel]
    var blanks: [Blank]

    static let empty = StubArchive(
        schemaVersion: StubArchive.schema,
        onboardingComplete: false,
        volumes: [],
        well: .empty,
        boards: [],
        fileMarks: [],
        nailMarks: [],
        earlyMarks: [],
        hollowMarks: [],
        peels: [],
        blanks: []
    )

    func volume(_ id: UUID) -> Volume? {
        volumes.first { $0.id == id }
    }

    func slip(_ id: UUID) -> (volume: Volume, slip: Slip)? {
        for volume in volumes {
            if let slip = volume.slips.first(where: { $0.id == id }) {
                return (volume, slip)
            }
        }
        return nil
    }

    func board(for dayKey: Int) -> Board? {
        boards.first { $0.dayKey == dayKey }
    }

    /// Opens a held volume. One quote-store starts empty. Reread defaults to no.
    mutating func openVolume(title: String, author: String, totalPages: Int, currentPage: Int) -> Result<Volume, DeskEffect.Refusal> {
        guard totalPages > 0, currentPage >= 1, currentPage <= totalPages else {
            return .failure(.pageOutOfRange)
        }
        let volume = Volume(
            id: UUID(),
            title: title,
            author: author,
            totalPages: totalPages,
            currentPage: currentPage,
            stance: .held,
            reread: false,
            slips: [],
            frozenFraction: nil
        )
        volumes.append(volume)
        return .success(volume)
    }

    mutating func setPage(_ page: Int, on volumeID: UUID) -> DeskEffect.Refusal? {
        guard let index = volumes.firstIndex(where: { $0.id == volumeID }) else {
            return .missingVolume
        }
        guard volumes[index].isHeld else { return .alreadyClosed }
        guard page >= 1, page <= volumes[index].totalPages else { return .pageOutOfRange }
        volumes[index].currentPage = page
        return nil
    }

    /// Reread is yes or no. There is no star rating.
    mutating func setReread(_ reread: Bool, on volumeID: UUID) -> DeskEffect.Refusal? {
        guard let index = volumes.firstIndex(where: { $0.id == volumeID }) else {
            return .missingVolume
        }
        volumes[index].reread = reread
        return nil
    }

    mutating func writeSlip(text: String, page: Int, on volumeID: UUID) -> Result<Slip, DeskEffect.Refusal> {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .failure(.emptyLine) }
        guard let index = volumes.firstIndex(where: { $0.id == volumeID }) else {
            return .failure(.missingVolume)
        }
        guard volumes[index].isHeld else { return .failure(.alreadyClosed) }
        guard page >= 1, page <= volumes[index].totalPages else { return .failure(.pageOutOfRange) }
        let slip = Slip(id: UUID(), text: trimmed, page: page)
        volumes[index].slips.append(slip)
        return .success(slip)
    }

    /// Close on a held volume. A chosen slip writes FileMark and an MMDD stub.
    /// No slip writes HollowMark and leaves the volume held.
    mutating func closeVolume(
        _ volumeID: UUID,
        slipID: UUID?,
        on date: Date,
        calendar: Calendar
    ) -> DeskEffect {
        guard let index = volumes.firstIndex(where: { $0.id == volumeID }) else {
            return .refused(.missingVolume)
        }
        guard volumes[index].isHeld else { return .refused(.notHeld) }
        let dayKey = DayStamp.dayKey(date, calendar: calendar)
        guard let slipID else {
            let mark = HollowMark(id: UUID(), dayKey: dayKey, volumeID: volumeID, recordedAt: date)
            hollowMarks.append(mark)
            return .hollow(mark)
        }
        guard volumes[index].slips.contains(where: { $0.id == slipID }) else {
            return .refused(.slipMissing)
        }
        let mark = FileMark(
            id: UUID(),
            dayKey: dayKey,
            volumeID: volumeID,
            slipID: slipID,
            recordedAt: date
        )
        fileMarks.append(mark)
        let stub = Stub(
            id: UUID(),
            volumeID: volumeID,
            slipID: slipID,
            anniversary: DayStamp.anniversary(dayKey),
            fileMarkID: mark.id
        )
        well.stubs.append(stub)
        volumes[index].frozenFraction = volumes[index].progressFraction
        volumes[index].stance = .closed
        _ = pass(on: date, calendar: calendar)
        return .filed(mark)
    }

    /// Nail seats the due stub. Nail on Bare writes EarlyMark. Nail while Nailed is refused.
    mutating func nailDue(_ date: Date, calendar: Calendar) -> DeskEffect {
        _ = pass(on: date, calendar: calendar)
        let dayKey = DayStamp.dayKey(date, calendar: calendar)
        guard let index = boards.firstIndex(where: { $0.dayKey == dayKey }) else {
            return .refused(.notDue)
        }
        switch boards[index].phase {
        case .nailed:
            return .refused(.alreadyNailed)
        case .bare:
            let mark = EarlyMark(id: UUID(), dayKey: dayKey, recordedAt: date)
            earlyMarks.append(mark)
            return .early(mark)
        case .due:
            guard let stubID = boards[index].dueStubID,
                  let stubIndex = well.stubs.firstIndex(where: { $0.id == stubID })
            else {
                return .refused(.notDue)
            }
            let stub = well.stubs.remove(at: stubIndex)
            let mark = NailMark(
                id: UUID(),
                dayKey: dayKey,
                stubID: stub.id,
                slipID: stub.slipID,
                recordedAt: date
            )
            nailMarks.append(mark)
            boards[index].phase = .nailed
            boards[index].seatedSlipID = stub.slipID
            boards[index].lifted = stub
            boards[index].dueStubID = stub.id
            return .nailed(mark)
        }
    }

    /// Peel drops the nail, returns the stub to the well, then runs the match pass.
    mutating func peelNail(on date: Date, calendar: Calendar) -> DeskEffect {
        let dayKey = DayStamp.dayKey(date, calendar: calendar)
        guard let index = boards.firstIndex(where: { $0.dayKey == dayKey }),
              boards[index].phase == .nailed,
              let lifted = boards[index].lifted
        else {
            return .refused(.notNailed)
        }
        guard let nailIndex = nailMarks.lastIndex(where: { $0.dayKey == dayKey && $0.stubID == lifted.id }) else {
            return .refused(.notNailed)
        }
        let dropped = nailMarks.remove(at: nailIndex)
        well.stubs.append(lifted)
        boards[index].phase = .bare
        boards[index].seatedSlipID = nil
        boards[index].lifted = nil
        boards[index].dueStubID = nil
        let peel = Peel(
            id: UUID(),
            dayKey: dayKey,
            stubID: lifted.id,
            droppedNailID: dropped.id,
            recordedAt: date
        )
        peels.append(peel)
        _ = pass(on: date, calendar: calendar)
        return .peeled(peel)
    }

    /// Match pass. Oldest FileMark among today's month-day becomes Due.
    /// An empty well with nothing nailed writes Blank. Other stubs leave the board Bare.
    @discardableResult
    mutating func pass(on date: Date, calendar: Calendar) -> BoardFace {
        let dayKey = DayStamp.dayKey(date, calendar: calendar)
        let anniversary = DayStamp.anniversary(dayKey)
        if let existing = board(for: dayKey), existing.phase == .nailed {
            return face(on: date, calendar: calendar)
        }
        let waiting = well.waiting(on: anniversary)
        if waiting.isEmpty {
            if well.stubs.isEmpty {
                return writeBlank(dayKey: dayKey, on: date)
            }
            upsert(Board(dayKey: dayKey, phase: .bare, dueStubID: nil, seatedSlipID: nil, lifted: nil))
            return face(on: date, calendar: calendar)
        }
        let oldest = waiting.min { lhs, rhs in
            let left = fileMarks.first { $0.id == lhs.fileMarkID }
            let right = fileMarks.first { $0.id == rhs.fileMarkID }
            let leftDate = left?.recordedAt ?? .distantFuture
            let rightDate = right?.recordedAt ?? .distantFuture
            if leftDate != rightDate { return leftDate < rightDate }
            return lhs.id.uuidString < rhs.id.uuidString
        }
        upsert(
            Board(
                dayKey: dayKey,
                phase: .due,
                dueStubID: oldest?.id,
                seatedSlipID: nil,
                lifted: nil
            )
        )
        return face(on: date, calendar: calendar)
    }

    func face(on date: Date, calendar: Calendar) -> BoardFace {
        let dayKey = DayStamp.dayKey(date, calendar: calendar)
        guard let board = board(for: dayKey) else {
            return .blank(dayKey: dayKey)
        }
        switch board.phase {
        case .bare:
            return BoardFace(
                fold: .bare,
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
        case .due:
            return seatedFace(fold: .due, dayKey: dayKey, stubID: board.dueStubID, nailEnabled: true, peelEnabled: false)
        case .nailed:
            let stubID = board.lifted?.id ?? board.dueStubID
            return seatedFace(fold: .nailed, dayKey: dayKey, stubID: stubID, nailEnabled: false, peelEnabled: true)
        }
    }

    private func seatedFace(
        fold: BoardFace.Fold,
        dayKey: Int,
        stubID: UUID?,
        nailEnabled: Bool,
        peelEnabled: Bool
    ) -> BoardFace {
        let stub = stubID.flatMap { id in
            well.stubs.first { $0.id == id } ?? boards.compactMap(\.lifted).first { $0.id == id }
        }
        let resolved = stub.flatMap { slip($0.slipID) }
        return BoardFace(
            fold: fold,
            dayKey: dayKey,
            anniversary: DayStamp.anniversary(dayKey),
            stubID: stub?.id,
            volumeID: stub?.volumeID,
            slipID: resolved?.slip.id,
            line: resolved?.slip.text ?? "",
            page: resolved?.slip.page,
            nailEnabled: nailEnabled,
            peelEnabled: peelEnabled
        )
    }

    private mutating func writeBlank(dayKey: Int, on date: Date) -> BoardFace {
        boards.removeAll { $0.dayKey == dayKey }
        if !blanks.contains(where: { $0.dayKey == dayKey }) {
            blanks.append(Blank(id: UUID(), dayKey: dayKey, recordedAt: date))
        }
        return .blank(dayKey: dayKey)
    }

    private mutating func upsert(_ board: Board) {
        if let index = boards.firstIndex(where: { $0.dayKey == board.dayKey }) {
            boards[index] = board
        } else {
            boards.append(board)
        }
    }
}

extension StubArchive: Codable {
    private enum CodingKeys: String, CodingKey {
        case schemaVersion
        case onboardingComplete
        case volumes
        case well
        case boards
        case fileMarks
        case nailMarks
        case earlyMarks
        case hollowMarks
        case peels
        case blanks
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let version = try container.decode(Int.self, forKey: .schemaVersion)
        switch version {
        case 1:
            schemaVersion = version
            onboardingComplete = try container.decode(Bool.self, forKey: .onboardingComplete)
            volumes = try container.decode([Volume].self, forKey: .volumes)
            well = try container.decode(Well.self, forKey: .well)
            boards = try container.decode([Board].self, forKey: .boards)
            fileMarks = try container.decode([FileMark].self, forKey: .fileMarks)
            nailMarks = try container.decode([NailMark].self, forKey: .nailMarks)
            earlyMarks = try container.decode([EarlyMark].self, forKey: .earlyMarks)
            hollowMarks = try container.decode([HollowMark].self, forKey: .hollowMarks)
            peels = try container.decode([Peel].self, forKey: .peels)
            blanks = try container.decode([Blank].self, forKey: .blanks)
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .schemaVersion,
                in: container,
                debugDescription: "Unknown schemaVersion \(version)"
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(schemaVersion, forKey: .schemaVersion)
        try container.encode(onboardingComplete, forKey: .onboardingComplete)
        try container.encode(volumes, forKey: .volumes)
        try container.encode(well, forKey: .well)
        try container.encode(boards, forKey: .boards)
        try container.encode(fileMarks, forKey: .fileMarks)
        try container.encode(nailMarks, forKey: .nailMarks)
        try container.encode(earlyMarks, forKey: .earlyMarks)
        try container.encode(hollowMarks, forKey: .hollowMarks)
        try container.encode(peels, forKey: .peels)
        try container.encode(blanks, forKey: .blanks)
    }
}
