import XCTest
@testable import Stubwell

final class StubwellTests: XCTestCase {
    private var calendar: Calendar!

    override func setUp() {
        super.setUp()
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        calendar = gregorian
    }

    func testQuoteStoreIsOnePerVolumeAndFractionFreezesWithoutStars() {
        var archive = StubArchive.empty
        let opened = archive.openVolume(title: "Kindred", author: "Butler", totalPages: 300, currentPage: 40)
        guard case .success(let volume) = opened else {
            XCTFail("Expected a held volume")
            return
        }
        XCTAssertEqual(archive.setReread(true, on: volume.id), nil)
        XCTAssertEqual(archive.volume(volume.id)?.reread, true)
        XCTAssertEqual(archive.volume(volume.id)?.progressFraction ?? -1, 40.0 / 300.0, accuracy: 0.000_001)
        guard case .success(let first) = archive.writeSlip(text: "First line", page: 40, on: volume.id) else {
            XCTFail("Expected a slip")
            return
        }
        guard case .success = archive.writeSlip(text: "Second line", page: 40, on: volume.id) else {
            XCTFail("Expected a second slip in the same store")
            return
        }
        XCTAssertEqual(archive.volume(volume.id)?.slips.count, 2)
        XCTAssertEqual(archive.slip(first.id)?.volume.id, volume.id)
        let before = archive.volume(volume.id)?.progressFraction
        let filed = archive.closeVolume(volume.id, slipID: first.id, on: date(2026, 3, 2), calendar: calendar)
        guard case .filed = filed else {
            XCTFail("Expected FileMark")
            return
        }
        XCTAssertEqual(archive.volume(volume.id)?.stance, .closed)
        XCTAssertEqual(archive.volume(volume.id)?.progressFraction, before)
        XCTAssertEqual(archive.setPage(10, on: volume.id), .alreadyClosed)
        XCTAssertEqual(archive.writeSlip(text: "Too late", page: 10, on: volume.id), .failure(.alreadyClosed))
        XCTAssertEqual(archive.volume(volume.id)?.progressFraction, before)
        XCTAssertEqual(archive.openVolume(title: "Bad", author: "X", totalPages: 0, currentPage: 1), .failure(.pageOutOfRange))
    }

    func testNailEmptyPopulatedAndRefused() {
        var empty = StubArchive.empty
        let missing = empty.nailDue(date(2026, 5, 1), calendar: calendar)
        XCTAssertEqual(missing, .refused(.notDue))
        if case .blank = empty.pass(on: date(2026, 5, 1), calendar: calendar).fold {
            XCTAssertEqual(empty.blanks.count, 1)
        } else {
            XCTFail("Empty well writes Blank")
        }

        var archive = heldShelf()
        _ = addClosed(&archive, title: "Later", on: date(2026, 11, 2), page: 5, total: 50)
        let bare = archive.nailDue(date(2026, 6, 1), calendar: calendar)
        guard case .early = bare else {
            XCTFail("Nail on Bare writes EarlyMark")
            return
        }
        XCTAssertEqual(archive.face(on: date(2026, 6, 1), calendar: calendar).fold, .bare)

        let today = date(2026, 6, 2)
        let volume = archive.volumes[0]
        let slip = volume.slips[0]
        guard case .filed = archive.closeVolume(volume.id, slipID: slip.id, on: today, calendar: calendar) else {
            XCTFail("Expected a filing")
            return
        }
        XCTAssertEqual(archive.face(on: today, calendar: calendar).fold, .due)
        XCTAssertTrue(archive.face(on: today, calendar: calendar).nailEnabled)
        guard case .nailed = archive.nailDue(today, calendar: calendar) else {
            XCTFail("Expected NailMark")
            return
        }
        XCTAssertEqual(archive.face(on: today, calendar: calendar).fold, .nailed)
        XCTAssertEqual(archive.nailDue(today, calendar: calendar), .refused(.alreadyNailed))
        XCTAssertEqual(archive.nailMarks.count, 1)
    }

    func testFileThenNailEarlySecondNailAndPeel() {
        var archive = StubArchive.empty
        let olderDate = date(2024, 10, 26)
        let youngerDate = date(2025, 10, 26)
        let today = date(2026, 10, 26)
        let older = addClosed(&archive, title: "Older", on: olderDate, page: 10, total: 100)
        let younger = addClosed(&archive, title: "Younger", on: youngerDate, page: 20, total: 80)
        let face = archive.pass(on: today, calendar: calendar)
        XCTAssertEqual(face.fold, .due)
        XCTAssertEqual(face.stubID, older.stubID)
        XCTAssertNotEqual(face.stubID, younger.stubID)
        XCTAssertEqual(face.line, "Line from Older")

        guard case .nailed(let nail) = archive.nailDue(today, calendar: calendar) else {
            XCTFail("Expected the due stub to nail")
            return
        }
        XCTAssertEqual(nail.stubID, older.stubID)
        XCTAssertFalse(archive.well.stubs.contains { $0.id == older.stubID })
        XCTAssertTrue(archive.well.stubs.contains { $0.id == younger.stubID })
        XCTAssertEqual(archive.nailDue(today, calendar: calendar), .refused(.alreadyNailed))

        guard case .peeled = archive.peelNail(on: today, calendar: calendar) else {
            XCTFail("Expected Peel")
            return
        }
        XCTAssertTrue(archive.nailMarks.isEmpty)
        XCTAssertEqual(archive.face(on: today, calendar: calendar).fold, .due)
        XCTAssertEqual(archive.face(on: today, calendar: calendar).stubID, older.stubID)
        XCTAssertTrue(archive.well.stubs.contains { $0.id == older.stubID })
    }

    func testHollowCloseAndBareStay() {
        var archive = heldShelf()
        _ = addClosed(&archive, title: "Later", on: date(2026, 12, 2), page: 6, total: 60)
        let volume = archive.volumes[0]
        let effect = archive.closeVolume(volume.id, slipID: nil, on: date(2026, 1, 9), calendar: calendar)
        guard case .hollow = effect else {
            XCTFail("Close without a slip writes HollowMark")
            return
        }
        XCTAssertEqual(archive.volume(volume.id)?.stance, .held)
        XCTAssertEqual(archive.well.stubs.count, 1)
        XCTAssertEqual(archive.pass(on: date(2026, 1, 9), calendar: calendar).fold, .bare)
        XCTAssertEqual(
            archive.closeVolume(volume.id, slipID: UUID(), on: date(2026, 1, 9), calendar: calendar),
            .refused(.slipMissing)
        )
        guard case .filed = archive.closeVolume(volume.id, slipID: volume.slips[0].id, on: date(2026, 1, 9), calendar: calendar) else {
            XCTFail("Expected file")
            return
        }
        XCTAssertEqual(
            archive.closeVolume(volume.id, slipID: volume.slips[0].id, on: date(2026, 1, 10), calendar: calendar),
            .refused(.notHeld)
        )
        XCTAssertEqual(archive.peelNail(on: date(2026, 1, 9), calendar: calendar), .refused(.notNailed))
    }

    func testFoldIsPerDayKey() {
        var archive = StubArchive.empty
        let first = date(2026, 4, 4)
        let second = date(2026, 8, 8)
        _ = addClosed(&archive, title: "April", on: first, page: 3, total: 30)
        _ = addClosed(&archive, title: "August", on: second, page: 4, total: 40)
        XCTAssertEqual(archive.face(on: first, calendar: calendar).fold, .due)
        XCTAssertEqual(archive.pass(on: second, calendar: calendar).fold, .due)
        XCTAssertEqual(archive.board(for: DayStamp.dayKey(first, calendar: calendar))?.phase, .due)
        guard case .nailed = archive.nailDue(first, calendar: calendar) else {
            XCTFail("Expected nail on the April key")
            return
        }
        XCTAssertEqual(archive.board(for: DayStamp.dayKey(first, calendar: calendar))?.phase, .nailed)
        XCTAssertEqual(archive.board(for: DayStamp.dayKey(second, calendar: calendar))?.phase, .due)
        XCTAssertEqual(DayStamp.anniversary(DayStamp.dayKey(first, calendar: calendar)), 404)
    }

    func testPersistenceRoundTripAndCorruptFallback() async throws {
        let suite = "stubwell.tests.\(UUID().uuidString)"
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let store = StubStore(suiteName: suite, directory: folder, allowDemo: false)
        var archive = StubArchive.empty
        _ = addClosed(&archive, title: "Circe", on: date(2026, 7, 7), page: 12, total: 120)
        await store.commitNow(archive)
        let reloaded = StubStore(suiteName: suite, directory: folder, allowDemo: false)
        let loaded = await reloaded.load()
        XCTAssertNil(loaded.fault)
        XCTAssertEqual(loaded.archive.volumes.map(\.title), ["Circe"])
        XCTAssertEqual(loaded.archive.well.stubs.count, 1)
        XCTAssertEqual(loaded.archive.schemaVersion, 1)
        XCTAssertEqual(loaded.archive.face(on: date(2026, 7, 7), calendar: calendar).fold, .due)

        let defaults = UserDefaults(suiteName: suite)
        defaults?.set(Data("not-json".utf8), forKey: StubArchive.defaultsKey)
        let recovered = await reloaded.load()
        XCTAssertEqual(recovered.archive.volumes.map(\.title), ["Circe"])
        XCTAssertNotNil(recovered.fault)

        await store.resetAllData()
        let cleared = await store.load()
        XCTAssertTrue(cleared.archive.volumes.isEmpty)
        XCTAssertNil(cleared.fault)
        defaults?.removePersistentDomain(forName: suite)
        try? FileManager.default.removeItem(at: folder)
    }

    func testReviewLaunchParsesScreenArgument() {
        XCTAssertEqual(ReviewLaunch.screen(in: ["Stubwell", "-ReviewScreen", "today"]), "today")
        XCTAssertEqual(ReviewLaunch.screen(in: ["-ReviewScreen", "log"]), "log")
        XCTAssertEqual(ReviewLaunch.screen(in: ["-ReviewScreen", "goals"]), "goals")
        XCTAssertEqual(ReviewLaunch.screen(in: ["-ReviewScreen", "nailed"]), "nailed")
        XCTAssertNil(ReviewLaunch.screen(in: ["Stubwell"]))
        XCTAssertNil(ReviewLaunch.screen(in: ["-ReviewScreen"]))
    }

    func testDemoSeedLeavesTodayDue() {
        let now = date(2026, 10, 26)
        let demo = StubArchive.makeDemo(now: now, calendar: calendar)
        XCTAssertEqual(demo.volumes.filter(\.isHeld).count, 4)
        XCTAssertEqual(demo.volumes.filter { $0.stance == .closed }.count, 3)
        XCTAssertEqual(demo.well.stubs.count, 3)
        XCTAssertTrue(demo.onboardingComplete)
        let face = demo.face(on: now, calendar: calendar)
        XCTAssertEqual(face.fold, .due)
        XCTAssertTrue(face.nailEnabled)
        XCTAssertFalse(face.line.isEmpty)
        let anniversaries = Set(demo.well.stubs.map(\.anniversary))
        XCTAssertEqual(anniversaries.count, 3)
        XCTAssertTrue(anniversaries.contains(DayStamp.anniversary(DayStamp.dayKey(now, calendar: calendar))))
    }

    private func heldShelf() -> StubArchive {
        var archive = StubArchive.empty
        guard case .success(let volume) = archive.openVolume(
            title: "Piranesi",
            author: "Clarke",
            totalPages: 245,
            currentPage: 88
        ) else {
            return archive
        }
        _ = archive.writeSlip(text: "The Beauty of the House is immeasurable.", page: 88, on: volume.id)
        _ = archive.pass(on: date(2026, 6, 1), calendar: calendar)
        return archive
    }

    private struct Filed {
        var stubID: UUID
    }

    private func addClosed(
        _ archive: inout StubArchive,
        title: String,
        on date: Date,
        page: Int,
        total: Int
    ) -> Filed {
        guard case .success(let volume) = archive.openVolume(
            title: title,
            author: "Reader",
            totalPages: total,
            currentPage: page
        ) else {
            XCTFail("open")
            return Filed(stubID: UUID())
        }
        guard case .success(let slip) = archive.writeSlip(text: "Line from \(title)", page: page, on: volume.id) else {
            XCTFail("slip")
            return Filed(stubID: UUID())
        }
        guard case .filed = archive.closeVolume(volume.id, slipID: slip.id, on: date, calendar: calendar) else {
            XCTFail("close")
            return Filed(stubID: UUID())
        }
        return Filed(stubID: archive.well.stubs.last?.id ?? UUID())
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 15)) ?? Date(timeIntervalSince1970: 0)
    }
}
