import SwiftUI

/// Coming up. One next date, then later dates, then nails by day.
struct DashboardView: View {
    @Environment(BoardDesk.self) private var desk
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var opened: UUID?
    @State private var showAdd = false
    @State private var pending: UUID?

    private var archive: StubArchive {
        _ = desk.revision
        return desk.snapshot()
    }

    private var slots: [ReturnSlot] {
        DayReadout.slots(in: archive)
    }

    private var groups: [NailGroup] {
        let grouped = Dictionary(grouping: archive.nailMarks, by: \.dayKey)
        return grouped.keys.sorted(by: >).map { key in
            NailGroup(id: key, marks: grouped[key] ?? [])
        }
    }

    var body: some View {
        Group {
            if desk.fault != nil && slots.isEmpty && archive.nailMarks.isEmpty {
                FaultPage(retry: { Task { await desk.retry() } }, reset: { Task { await desk.resetAllData() } })
            } else if slots.isEmpty && archive.nailMarks.isEmpty {
                EmptyPage(
                    imageName: "swl_WellStack",
                    headline: "Nothing is filed yet.",
                    line: "Close a finished book, then nail the line on its date.",
                    actionTitle: "Add a book",
                    action: { showAdd = true }
                )
            } else {
                list
            }
        }
        .background(DesignTokens.bg.ignoresSafeArea())
        .navigationDestination(item: $opened) { id in
            BookRoute(volumeID: id)
        }
        .sheet(isPresented: $showAdd, onDismiss: {
            if let pending {
                opened = pending
                self.pending = nil
            }
        }) {
            DeskSheet(title: "Add a book", instant: false) {
                AddBookSheet { id in
                    pending = id
                    showAdd = false
                }
            }
        }
    }

    private var list: some View {
        List {
            if let hero = slots.first {
                Section {
                    Button {
                        opened = hero.volumeID
                    } label: {
                        VStack(alignment: .leading, spacing: Spacing.s8) {
                            Text(hero.date, format: .dateTime.month(.wide).day().year())
                                .appFont(.title, longLine: true)
                                .foregroundStyle(DesignTokens.ink)
                                .fixedSize(horizontal: false, vertical: true)
                            Text("Next")
                                .appFont(.caption)
                                .foregroundStyle(DesignTokens.ink)
                            Text(hero.line)
                                .appFont(.body, longLine: hero.line.count > 48)
                                .foregroundStyle(DesignTokens.ink)
                                .fixedSize(horizontal: false, vertical: true)
                            HStack(alignment: .firstTextBaseline, spacing: Spacing.s12) {
                                Text(hero.title)
                                    .appFont(.caption)
                                    .lineLimit(2)
                                    .fixedSize(horizontal: false, vertical: true)
                                Spacer(minLength: Spacing.s8)
                                pageLabel(hero.page)
                                    .layoutPriority(1)
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: Hit.min, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(SnapButtonStyle(role: .plain))
                }
            }
            if slots.count > 1 {
                Section {
                    ForEach(Array(slots.dropFirst())) { slot in
                        Button {
                            opened = slot.volumeID
                        } label: {
                            HStack(alignment: .top, spacing: Spacing.s12) {
                                VStack(alignment: .leading, spacing: Spacing.s4) {
                                    Text(slot.date, format: .dateTime.month(.abbreviated).day())
                                        .appFont(.body)
                                        .foregroundStyle(DesignTokens.ink)
                                        .fixedSize(horizontal: false, vertical: true)
                                    Text(slot.title)
                                        .appFont(.caption)
                                        .foregroundStyle(DesignTokens.ink)
                                        .lineLimit(2)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                Spacer(minLength: Spacing.s8)
                                pageLabel(slot.page)
                                    .layoutPriority(1)
                            }
                            .frame(maxWidth: .infinity, minHeight: Hit.min, alignment: .leading)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(SnapButtonStyle(role: .plain))
                    }
                } header: {
                    Text("Later")
                        .appFont(.caption)
                        .foregroundStyle(DesignTokens.muted)
                }
            }
            Section {
                if groups.isEmpty {
                    Text("No nails yet. Nail this line when it is due.")
                        .appFont(.body, longLine: true)
                        .foregroundStyle(DesignTokens.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, minHeight: Hit.min, alignment: .leading)
                } else {
                    ForEach(groups) { group in
                        VStack(alignment: .leading, spacing: Spacing.s8) {
                            Text(DayReadout.label(dayKey: group.id))
                                .appFont(.caption)
                                .foregroundStyle(DesignTokens.muted)
                            ForEach(group.marks) { mark in
                                nailRow(mark)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            } header: {
                HStack {
                    Text("Nails")
                        .appFont(.caption)
                        .foregroundStyle(DesignTokens.muted)
                    Spacer(minLength: Spacing.s8)
                    Text(archive.nailMarks.count, format: .number.precision(.fractionLength(0)))
                        .appFont(.caption)
                        .foregroundStyle(DesignTokens.ink)
                        .monospacedDigit()
                        .contentTransition(reduceMotion ? .opacity : .numericText(value: Double(archive.nailMarks.count)))
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(DesignTokens.bg)
    }

    private func nailRow(_ mark: NailMark) -> some View {
        let resolved = archive.slip(mark.slipID)
        let title = resolved.flatMap { archive.volume($0.volume.id)?.title } ?? "unknown"
        let line = resolved?.slip.text ?? "unknown"
        return Button {
            if let id = resolved?.volume.id {
                opened = id
            }
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.s12) {
                VStack(alignment: .leading, spacing: Spacing.s4) {
                    Text(line.isEmpty ? "unknown" : line)
                        .appFont(.body, longLine: line.count > 48)
                        .foregroundStyle(DesignTokens.ink)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(title)
                        .appFont(.caption)
                        .foregroundStyle(DesignTokens.muted)
                        .lineLimit(1)
                }
                Spacer(minLength: Spacing.s8)
                pageLabel(resolved?.slip.page)
                    .layoutPriority(1)
            }
            .frame(maxWidth: .infinity, minHeight: Hit.min, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(SnapButtonStyle(role: .plain))
    }

    @ViewBuilder
    private func pageLabel(_ page: Int?) -> some View {
        if let page {
            Text(page, format: .number.precision(.fractionLength(0)))
                .appFont(.caption)
                .foregroundStyle(DesignTokens.ink)
                .monospacedDigit()
        } else {
            Text("unknown")
                .appFont(.caption)
                .foregroundStyle(DesignTokens.muted)
        }
    }
}

private struct NailGroup: Identifiable {
    var id: Int
    var marks: [NailMark]
}
