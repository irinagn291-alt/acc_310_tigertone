import Foundation

/// Load result. A decode failure keeps the last good archive and names reset.
struct ArchiveLoad: Equatable, Sendable {
    var archive: StubArchive
    var fault: String?
}

/// StubStore is the only storage seam.
/// Views never touch UserDefaults or the file. Writes are debounced, atomic,
/// and flushed on inactive, background, and reset.
actor StubStore {
    private let suiteName: String?
    private let directoryOverride: URL?
    private let allowDemo: Bool
    private var directory: URL?
    private var latest: StubArchive?
    private var generation = 0
    private var fault: String?

    init(suiteName: String?, directory: URL?, allowDemo: Bool) {
        self.suiteName = suiteName
        self.directoryOverride = directory
        self.allowDemo = allowDemo
    }

    static func live() -> StubStore {
        #if targetEnvironment(simulator)
        StubStore(suiteName: nil, directory: nil, allowDemo: true)
        #else
        StubStore(suiteName: nil, directory: nil, allowDemo: false)
        #endif
    }

    func load() -> ArchiveLoad {
        let defaults = userDefaults()
        let primary = defaults.data(forKey: StubArchive.defaultsKey)
        if let primary, let archive = decode(primary) {
            latest = archive
            fault = nil
            return ArchiveLoad(archive: archive, fault: nil)
        }
        let primaryFailed = primary != nil
        if let file = readFile(named: "archive.json"), let archive = decode(file) {
            defaults.set(file, forKey: StubArchive.defaultsKey)
            latest = archive
            fault = primaryFailed ? Self.recoverableFault : nil
            return ArchiveLoad(archive: archive, fault: fault)
        }
        if let backup = readFile(named: "archive.json.backup"), let archive = decode(backup) {
            if let data = try? Self.encoder.encode(archive) {
                defaults.set(data, forKey: StubArchive.defaultsKey)
                writeAtomically(data)
            }
            latest = archive
            fault = Self.recoverableFault
            return ArchiveLoad(archive: archive, fault: fault)
        }
        latest = .empty
        if primaryFailed || readFile(named: "archive.json") != nil {
            fault = Self.recoverableFault
        }
        return ArchiveLoad(archive: .empty, fault: fault)
    }

    func shouldSeed(archiveIsEmpty: Bool) -> Bool {
        guard allowDemo, archiveIsEmpty else { return false }
        return userDefaults().bool(forKey: StubArchive.demoKey) == false
    }

    func commitNow(_ archive: StubArchive) {
        generation += 1
        latest = archive
        persist(archive)
    }

    func note(_ archive: StubArchive) async {
        latest = archive
        generation += 1
        let ticket = generation
        try? await Task.sleep(nanoseconds: 300_000_000)
        guard !Task.isCancelled, ticket == generation else { return }
        guard let latest else { return }
        persist(latest)
    }

    func flush() {
        generation += 1
        guard let latest else { return }
        persist(latest)
    }

    func markDemo(using archive: StubArchive) {
        userDefaults().set(true, forKey: StubArchive.demoKey)
        commitNow(archive)
    }

    func resetAllData() {
        generation += 1
        let defaults = userDefaults()
        defaults.removeObject(forKey: StubArchive.defaultsKey)
        defaults.set(true, forKey: StubArchive.demoKey)
        deleteArchiveFiles()
        latest = .empty
        persist(.empty)
        fault = nil
    }

    func exportData() -> Data? {
        guard let latest else { return nil }
        return try? Self.encoder.encode(latest)
    }

    func currentFault() -> String? {
        fault
    }

    private func persist(_ archive: StubArchive) {
        do {
            let data = try Self.encoder.encode(archive)
            userDefaults().set(data, forKey: StubArchive.defaultsKey)
            writeAtomically(data)
            fault = nil
        } catch {
            fault = "The board could not be saved. \(error.localizedDescription)"
        }
    }

    private func writeAtomically(_ data: Data) {
        do {
            let folder = try supportDirectory()
            let url = folder.appendingPathComponent("archive.json")
            let backup = folder.appendingPathComponent("archive.json.backup")
            if FileManager.default.fileExists(atPath: url.path) {
                if FileManager.default.fileExists(atPath: backup.path) {
                    try FileManager.default.removeItem(at: backup)
                }
                try FileManager.default.copyItem(at: url, to: backup)
            }
            try data.write(to: url, options: .atomic)
        } catch {
            fault = "The board could not be saved. \(error.localizedDescription)"
        }
    }

    private func readFile(named name: String) -> Data? {
        guard let folder = try? supportDirectory() else { return nil }
        let url = folder.appendingPathComponent(name)
        return try? Data(contentsOf: url)
    }

    private func deleteArchiveFiles() {
        guard let folder = try? supportDirectory() else { return }
        for name in ["archive.json", "archive.json.backup"] {
            let url = folder.appendingPathComponent(name)
            if FileManager.default.fileExists(atPath: url.path) {
                do {
                    try FileManager.default.removeItem(at: url)
                } catch {
                    fault = "Reset could not clear the saved board. \(error.localizedDescription)"
                }
            }
        }
    }

    private func supportDirectory() throws -> URL {
        if let directory { return directory }
        if let directoryOverride {
            try FileManager.default.createDirectory(at: directoryOverride, withIntermediateDirectories: true)
            directory = directoryOverride
            return directoryOverride
        }
        let base = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let folder = base.appendingPathComponent("Tigertone", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        directory = folder
        return folder
    }

    private func userDefaults() -> UserDefaults {
        if let suiteName, let suite = UserDefaults(suiteName: suiteName) {
            return suite
        }
        return .standard
    }

    private func decode(_ data: Data) -> StubArchive? {
        try? Self.decoder.decode(StubArchive.self, from: data)
    }

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }()

    private static let decoder = JSONDecoder()

    private static let recoverableFault = "Saved board could not be read. Reset is the way forward."
}
