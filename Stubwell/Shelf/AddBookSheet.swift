import SwiftUI

/// Adds a held book with sane page defaults. The line is written on the next page.
struct AddBookSheet: View {
    var onCreated: (UUID) -> Void
    @Environment(BoardDesk.self) private var desk
    @FocusState private var focus: Field?
    @State private var title = ""
    @State private var author = ""
    @State private var pages = "300"
    @State private var start = "1"
    @State private var note: String?
    @State private var saving = false

    private enum Field: Hashable {
        case title
        case author
        case pages
        case start
    }

    private var pageCount: Int? {
        let digits = pages.filter(\.isNumber)
        guard let value = Int(digits), value >= 1 else { return nil }
        return value
    }

    private var startPage: Int? {
        let digits = start.filter(\.isNumber)
        guard let value = Int(digits), value >= 1, let pageCount, value <= pageCount else { return nil }
        return value
    }

    private var dirty: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !author.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s16) {
                field("Title", text: $title, field: .title, next: .author)
                field("Author", text: $author, field: .author, next: .pages)
                field("Pages", text: $pages, field: .pages, next: .start, digits: true)
                field("Start page", text: $start, field: .start, next: nil, digits: true)
                if let note {
                    Text(note)
                        .appFont(.caption)
                        .foregroundStyle(DesignTokens.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Button {
                    save()
                } label: {
                    Text("Add a book")
                        .appFont(.body)
                }
                .buttonStyle(SnapButtonStyle(role: .prominent, fills: true))
                .disabled(saving || title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || pageCount == nil || startPage == nil)
            }
            .padding(Spacing.s20)
        }
        .scrollDismissesKeyboard(.immediately)
        .background(DesignTokens.bg.ignoresSafeArea())
        .preference(key: DraftSignal.self, value: dirty)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focus = nil }
            }
        }
    }

    private func field(_ label: String, text: Binding<String>, field: Field, next: Field?, digits: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s8) {
            Text(label)
                .appFont(.caption)
                .foregroundStyle(DesignTokens.muted)
            TextField(label, text: text)
                .appFont(.body)
                .foregroundStyle(DesignTokens.ink)
                .keyboardType(digits ? .numberPad : .default)
                .textInputAutocapitalization(digits ? .never : .words)
                .focused($focus, equals: field)
                .submitLabel(next == nil ? .done : .next)
                .onSubmit {
                    focus = next
                }
                .onChange(of: text.wrappedValue) { _, newValue in
                    guard digits else { return }
                    let cleaned = newValue.filter(\.isNumber)
                    if cleaned != newValue {
                        text.wrappedValue = cleaned
                    }
                }
                .padding(Spacing.s12)
                .frame(minHeight: Hit.min)
                .background {
                    RoundedRectangle(cornerRadius: Radius.chip, style: .continuous)
                        .fill(DesignTokens.surface)
                }
        }
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let pageCount, let startPage else {
            note = "Name the book and a page count."
            return
        }
        saving = true
        let writer = author.trimmingCharacters(in: .whitespacesAndNewlines)
        let result = desk.openVolume(
            title: trimmed,
            author: writer.isEmpty ? "Unknown" : writer,
            totalPages: pageCount,
            currentPage: startPage
        )
        saving = false
        switch result {
        case .success(let volume):
            onCreated(volume.id)
        case .failure:
            note = refusalNote(for: desk.lastEffect) ?? "That book could not be added. Try again."
        }
    }
}
