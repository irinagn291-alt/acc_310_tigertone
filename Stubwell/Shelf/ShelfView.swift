import SwiftUI

/// Shelf lists held and finished books. The first held book is the tall row.
struct ShelfView: View {
    @Environment(BoardDesk.self) private var desk
    @State private var opened: UUID?
    @State private var showAdd = false
    @State private var pending: UUID?

    private var archive: StubArchive {
        _ = desk.revision
        return desk.snapshot()
    }

    private var held: [Volume] { archive.volumes.filter(\.isHeld) }
    private var closed: [Volume] { archive.volumes.filter { !$0.isHeld } }

    var body: some View {
        Group {
            if desk.fault != nil && archive.volumes.isEmpty {
                FaultPage(retry: { Task { await desk.retry() } }, reset: { Task { await desk.resetAllData() } })
            } else if archive.volumes.isEmpty {
                EmptyPage(
                    imageName: "swl_SpineBlock",
                    headline: "The shelf is empty.",
                    line: "Set down your first book, and leave a thought in the margins.",
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
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAdd = true
                } label: {
                    Image(systemName: "plus")
                        .frame(minWidth: Hit.min, minHeight: Hit.min)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Add a book")
            }
        }
    }

    private var list: some View {
        List {
            if let first = held.first {
                Section {
                    bookButton(first, featured: true)
                    ForEach(held.dropFirst()) { volume in
                        bookButton(volume, featured: false)
                    }
                } header: {
                    Text("Reading")
                        .appFont(.caption)
                        .foregroundStyle(DesignTokens.muted)
                }
            }
            if !closed.isEmpty {
                Section {
                    ForEach(closed) { volume in
                        bookButton(volume, featured: false)
                    }
                } header: {
                    Text("Finished")
                        .appFont(.caption)
                        .foregroundStyle(DesignTokens.muted)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(DesignTokens.bg)
    }

    private func bookButton(_ volume: Volume, featured: Bool) -> some View {
        Button {
            opened = volume.id
        } label: {
            VStack(alignment: .leading, spacing: Spacing.s8) {
                HStack(alignment: .firstTextBaseline, spacing: Spacing.s12) {
                    Text(volume.title)
                        .appFont(featured ? .title : .body, longLine: volume.title.count > 42)
                        .foregroundStyle(DesignTokens.ink)
                        .lineLimit(featured ? 2 : 1)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: Spacing.s8)
                    Text(volume.progressFraction, format: .number.precision(.fractionLength(0...1)))
                        .appFont(.caption)
                        .foregroundStyle(DesignTokens.ink)
                        .monospacedDigit()
                        .layoutPriority(1)
                }
                Text(volume.author.isEmpty ? "unknown" : volume.author)
                    .appFont(.caption)
                    .foregroundStyle(DesignTokens.muted)
                    .lineLimit(1)
                if volume.isHeld {
                    ProgressView(value: volume.progressFraction)
                        .tint(DesignTokens.accent)
                        .accessibilityLabel("Read")
                } else {
                    Text(volume.reread ? "Read again" : "Once")
                        .appFont(.caption)
                        .foregroundStyle(DesignTokens.ink)
                }
            }
            .frame(maxWidth: .infinity, minHeight: Hit.min, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(SnapButtonStyle(role: .plain))
        .listRowInsets(EdgeInsets(top: Spacing.s8, leading: Spacing.s16, bottom: Spacing.s8, trailing: Spacing.s16))
        .listRowBackground(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(.regularMaterial)
                .padding(.horizontal, Spacing.s8)
                .padding(.vertical, Spacing.s4)
        )
        .listRowSeparator(.hidden)
    }
}

struct BookRoute: View {
    var volumeID: UUID
    @Environment(BoardDesk.self) private var desk

    var body: some View {
        let _ = desk.revision
        if desk.snapshot().volume(volumeID)?.isHeld == true {
            VolumePage(volumeID: volumeID)
        } else {
            ClosedPage(volumeID: volumeID)
        }
    }
}
