import Foundation
import Observation

/// BoardDesk is the state between the archive and the quotes surface.
/// It publishes the folded face. Mark rules stay on StubArchive.
@MainActor
@Observable
final class BoardDesk {
    private(set) var face: BoardFace
    private(set) var fault: String?
    private(set) var lastEffect: DeskEffect?
    private(set) var ready = false
    private(set) var revision = 0
    private(set) var onboardingComplete = false
    private var archive: StubArchive
    private let store: StubStore
    private var prepared = false
    private var noted: Task<Void, Never>?

    init(store: StubStore, now: Date = Date(), calendar: Calendar = .current) {
        self.store = store
        archive = .empty
        face = .blank(dayKey: DayStamp.dayKey(now, calendar: calendar))
    }

    func prepare(now: Date = Date(), calendar: Calendar = .current) async {
        if prepared {
            while !ready {
                await Task.yield()
            }
            return
        }
        prepared = true
        let loaded = await store.load()
        archive = loaded.archive
        fault = loaded.fault
        if await store.shouldSeed(archiveIsEmpty: archive.volumes.isEmpty && archive.fileMarks.isEmpty) {
            archive = StubArchive.makeDemo(now: now, calendar: calendar)
            await store.markDemo(using: archive)
            fault = nil
        }
        archive.pass(on: now, calendar: calendar)
        publish(now: now, calendar: calendar)
        ready = true
    }

    func nail(now: Date = Date(), calendar: Calendar = .current) {
        lastEffect = archive.nailDue(now, calendar: calendar)
        publish(now: now, calendar: calendar)
        scheduleSave()
    }

    func peel(now: Date = Date(), calendar: Calendar = .current) {
        lastEffect = archive.peelNail(on: now, calendar: calendar)
        publish(now: now, calendar: calendar)
        scheduleSave()
    }

    func close(volumeID: UUID, slipID: UUID?, now: Date = Date(), calendar: Calendar = .current) {
        lastEffect = archive.closeVolume(volumeID, slipID: slipID, on: now, calendar: calendar)
        publish(now: now, calendar: calendar)
        scheduleSave()
    }

    func snapshot() -> StubArchive {
        archive
    }

    func flush() async {
        noted?.cancel()
        noted = nil
        await store.flush()
    }

    func resetAllData(now: Date = Date(), calendar: Calendar = .current) async {
        noted?.cancel()
        noted = nil
        await store.resetAllData()
        archive = .empty
        lastEffect = nil
        fault = nil
        publish(now: now, calendar: calendar)
    }

    /// Moves the fold when the civil day changes while the app stays open.
    func align(now: Date = Date(), calendar: Calendar = .current) {
        let key = DayStamp.dayKey(now, calendar: calendar)
        guard key != face.dayKey else { return }
        archive.pass(on: now, calendar: calendar)
        publish(now: now, calendar: calendar)
        scheduleSave()
    }

    func finishOnboarding(now: Date = Date(), calendar: Calendar = .current) {
        archive.onboardingComplete = true
        publish(now: now, calendar: calendar)
        scheduleSave()
    }

    func replayOnboarding(now: Date = Date(), calendar: Calendar = .current) {
        archive.onboardingComplete = false
        publish(now: now, calendar: calendar)
        scheduleSave()
    }

    func retry(now: Date = Date(), calendar: Calendar = .current) async {
        let loaded = await store.load()
        archive = loaded.archive
        fault = loaded.fault
        archive.pass(on: now, calendar: calendar)
        publish(now: now, calendar: calendar)
    }

    func exportText() async -> String? {
        await store.commitNow(archive)
        guard let data = await store.exportData() else { return nil }
        return String(data: data, encoding: .utf8)
    }

    @discardableResult
    func openVolume(
        title: String,
        author: String,
        totalPages: Int,
        currentPage: Int,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> Result<Volume, DeskEffect.Refusal> {
        let result = archive.openVolume(
            title: title,
            author: author,
            totalPages: totalPages,
            currentPage: currentPage
        )
        if case .failure(let refusal) = result {
            lastEffect = .refused(refusal)
        }
        publish(now: now, calendar: calendar)
        scheduleSave()
        return result
    }

    @discardableResult
    func setPage(_ page: Int, on volumeID: UUID, now: Date = Date(), calendar: Calendar = .current) -> DeskEffect.Refusal? {
        let refusal = archive.setPage(page, on: volumeID)
        if let refusal {
            lastEffect = .refused(refusal)
        }
        publish(now: now, calendar: calendar)
        scheduleSave()
        return refusal
    }

    @discardableResult
    func setReread(_ reread: Bool, on volumeID: UUID, now: Date = Date(), calendar: Calendar = .current) -> DeskEffect.Refusal? {
        let refusal = archive.setReread(reread, on: volumeID)
        if let refusal {
            lastEffect = .refused(refusal)
        }
        publish(now: now, calendar: calendar)
        scheduleSave()
        return refusal
    }

    @discardableResult
    func writeSlip(text: String, page: Int, on volumeID: UUID, now: Date = Date(), calendar: Calendar = .current) -> Result<Slip, DeskEffect.Refusal> {
        let result = archive.writeSlip(text: text, page: page, on: volumeID)
        if case .failure(let refusal) = result {
            lastEffect = .refused(refusal)
        }
        publish(now: now, calendar: calendar)
        scheduleSave()
        return result
    }

    private func publish(now: Date, calendar: Calendar) {
        face = archive.face(on: now, calendar: calendar)
        onboardingComplete = archive.onboardingComplete
        revision += 1
    }

    private func scheduleSave() {
        let snapshot = archive
        noted?.cancel()
        noted = Task { await store.note(snapshot) }
    }
}
