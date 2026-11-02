import SwiftUI
import UIKit

/// Root chrome. Quotes stays up. Shelf, dates, and settings arrive as sheets.
struct ContentView: View {
    @Environment(BoardDesk.self) private var desk
    @Environment(\.scenePhase) private var scenePhase
    @State private var coverKey: String?
    @State private var didReadCover = false
    @State private var holdPlaceholder = false
    @State private var showShelf = false
    @State private var showDates = false
    @State private var showSettings = false
    @State private var showAdd = false
    @State private var showVolume = false
    @State private var showClosed = false
    @State private var showFile = false
    @State private var volumeID: UUID?
    @State private var closedID: UUID?
    @State private var fileID: UUID?
    @State private var pendingVolume: UUID?

    private var instantSheets: Bool { coverKey != nil }

    var body: some View {
        Group {
            if desk.ready && !desk.onboardingComplete {
                OnboardingView {
                    desk.finishOnboarding()
                }
            } else {
                QuotesView(
                    holdPlaceholder: holdPlaceholder,
                    openShelf: { showShelf = true },
                    openDates: { showDates = true },
                    openSettings: { showSettings = true },
                    addBook: { showAdd = true }
                )
            }
        }
        .foregroundStyle(DesignTokens.ink)
        .tint(DesignTokens.accent)
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showShelf) {
            DeskSheet(title: "Shelf", instant: instantSheets) {
                ShelfView()
            }
        }
        .sheet(isPresented: $showDates) {
            DeskSheet(title: "Coming up", instant: instantSheets) {
                DashboardView()
            }
        }
        .sheet(isPresented: $showSettings) {
            DeskSheet(title: "Settings", instant: instantSheets) {
                SettingsView()
            }
        }
        .sheet(isPresented: $showAdd, onDismiss: {
            if let pendingVolume {
                volumeID = pendingVolume
                showVolume = true
                self.pendingVolume = nil
            }
        }) {
            DeskSheet(title: "Add a book", instant: instantSheets) {
                AddBookSheet { id in
                    pendingVolume = id
                    showAdd = false
                }
            }
        }
        .sheet(isPresented: $showVolume) {
            DeskSheet(title: "Reading", instant: instantSheets) {
                if let volumeID {
                    VolumePage(volumeID: volumeID)
                }
            }
        }
        .sheet(isPresented: $showClosed) {
            DeskSheet(title: "Finished", instant: instantSheets) {
                if let closedID {
                    ClosedPage(volumeID: closedID)
                }
            }
        }
        .sheet(isPresented: $showFile) {
            DeskSheet(title: "Close book", instant: instantSheets) {
                if let fileID {
                    FilePage(volumeID: fileID)
                }
            }
        }
        .task {
            try? await Task.sleep(nanoseconds: 150_000_000)
            if !desk.ready {
                holdPlaceholder = true
            }
        }
        .task {
            await desk.prepare()
            readCoverIfNeeded()
            await watchMidnight()
        }
        .onChange(of: desk.onboardingComplete) { _, done in
            if done {
                readCoverIfNeeded()
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                desk.align()
            }
        }
    }

    private func readCoverIfNeeded() {
        guard desk.ready, desk.onboardingComplete, !didReadCover else { return }
        didReadCover = true
        let key = ReviewLaunch.screen
        coverKey = key
        let archive = desk.snapshot()
        switch key {
        case "log", "dashboard":
            showDates = true
        case "goals", "shelf":
            showShelf = true
        case "settings":
            showSettings = true
        case "volume":
            if let id = archive.volumes.first(where: \.isHeld)?.id {
                volumeID = id
                showVolume = true
            }
        case "file":
            if let id = archive.volumes.first(where: { $0.isHeld && !$0.slips.isEmpty })?.id {
                fileID = id
                showFile = true
            }
        case "closed":
            if let id = archive.volumes.first(where: { !$0.isHeld })?.id {
                closedID = id
                showClosed = true
            }
        case "nailed":
            if desk.face.nailEnabled {
                desk.nail()
                if case .nailed = desk.lastEffect {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }
            }
        default:
            break
        }
    }

    private func watchMidnight() async {
        let calendar = Calendar.current
        while !Task.isCancelled {
            let now = Date()
            desk.align(now: now, calendar: calendar)
            let start = calendar.startOfDay(for: now)
            let next = calendar.date(byAdding: .day, value: 1, to: start) ?? now.addingTimeInterval(60 * 60)
            let delay = max(1, next.timeIntervalSinceNow + 1)
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
    }
}

#Preview {
    ContentView()
        .environment(BoardDesk(store: StubStore(suiteName: "preview.stubwell", directory: nil, allowDemo: false)))
}
