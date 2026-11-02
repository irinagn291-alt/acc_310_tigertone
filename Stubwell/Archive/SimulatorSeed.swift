import Foundation

/// Simulator shelf. Four held volumes with slips on different pages, three closed
/// volumes, one stub due today, and two stubs on later month-days.
extension StubArchive {
    static func makeDemo(now: Date, calendar: Calendar) -> StubArchive {
        var archive = StubArchive.empty
        archive.onboardingComplete = true
        let held: [(String, String, Int, Int, String)] = [
            ("The Left Hand of Darkness", "Ursula K. Le Guin", 300, 40, "The king was pregnant."),
            ("Piranesi", "Susanna Clarke", 245, 88, "The Beauty of the House is immeasurable."),
            ("The Dispossessed", "Ursula K. Le Guin", 387, 12, "There was a wall."),
            ("Kindred", "Octavia E. Butler", 264, 190, "I lost an arm on my last trip home.")
        ]
        for item in held {
            guard case .success(let volume) = archive.openVolume(
                title: item.0,
                author: item.1,
                totalPages: item.2,
                currentPage: item.3
            ) else { continue }
            _ = archive.writeSlip(text: item.4, page: item.3, on: volume.id)
        }

        let laterA = calendar.date(byAdding: .day, value: 17, to: now) ?? now
        let laterB = calendar.date(byAdding: .day, value: 48, to: now) ?? now
        let closed: [(String, String, Int, Int, String, Date)] = [
            ("Parable of the Sower", "Octavia E. Butler", 345, 345, "All that you touch you change.", now),
            ("The Fifth Season", "N. K. Jemisin", 468, 400, "Let's start with the end of the world.", laterA),
            ("Circe", "Madeline Miller", 393, 210, "When I was born, the name for what I was did not exist.", laterB)
        ]
        for item in closed {
            guard case .success(let volume) = archive.openVolume(
                title: item.0,
                author: item.1,
                totalPages: item.2,
                currentPage: item.3
            ) else { continue }
            guard case .success(let slip) = archive.writeSlip(text: item.4, page: item.3, on: volume.id) else {
                continue
            }
            _ = archive.closeVolume(volume.id, slipID: slip.id, on: item.5, calendar: calendar)
        }
        _ = archive.pass(on: now, calendar: calendar)
        return archive
    }
}
