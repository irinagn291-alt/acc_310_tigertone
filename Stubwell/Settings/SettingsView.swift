import SwiftUI

/// Settings keeps export, reset, contact, and a replay of the introduction.
struct SettingsView: View {
    @Environment(BoardDesk.self) private var desk
    @Environment(\.dismiss) private var dismiss
    @State private var exportText: String?
    @State private var exportFailed = false
    @State private var exporting = false
    @State private var confirmReset = false
    @State private var showWait = false

    private let contact = URL(string: "https://stubwell-board.store/contact-us")

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s12) {
                sectionLabel("Introduction")
                Button {
                    desk.replayOnboarding()
                    dismiss()
                } label: {
                    Text("Show introduction")
                        .appFont(.body)
                        .frame(maxWidth: .infinity, minHeight: Hit.min, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(SnapButtonStyle(role: .plain))
                .cardFace()

                if let contact {
                    sectionLabel("Contact")
                    Link(destination: contact) {
                        HStack(spacing: Spacing.s12) {
                            Text("Contact")
                                .appFont(.body)
                                .foregroundStyle(DesignTokens.ink)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: Spacing.s8)
                            Image(systemName: "arrow.up.right")
                                .appFont(.caption)
                                .foregroundStyle(DesignTokens.accent)
                                .accessibilityHidden(true)
                        }
                        .frame(maxWidth: .infinity, minHeight: Hit.min, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Contact")
                    .cardFace()
                }

                sectionLabel("On this device")
                VStack(alignment: .leading, spacing: Spacing.s8) {
                    if let exportText {
                        ShareLink(item: exportText) {
                            Text("Export")
                                .appFont(.body)
                                .frame(maxWidth: .infinity, minHeight: Hit.min, alignment: .leading)
                                .contentShape(Rectangle())
                        }
                    } else {
                        Button {
                            Task { await loadExport() }
                        } label: {
                            Text(exporting && showWait ? "Preparing" : "Export")
                                .appFont(.body)
                                .frame(maxWidth: .infinity, minHeight: Hit.min, alignment: .leading)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(SnapButtonStyle(role: .plain))
                        .disabled(exporting)
                    }
                    if exportFailed {
                        Text("Export failed. Try again.")
                            .appFont(.caption)
                            .foregroundStyle(DesignTokens.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        Button("Try again") {
                            Task { await loadExport() }
                        }
                        .buttonStyle(SnapButtonStyle(role: .quiet, fills: true))
                    }
                }
                .cardFace()

                Button("Delete all", role: .destructive) {
                    confirmReset = true
                }
                .buttonStyle(SnapButtonStyle(role: .quiet, fills: true))
                Text("Delete every local book and line from this device.")
                    .appFont(.caption)
                    .foregroundStyle(DesignTokens.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, Spacing.s20)
            .padding(.top, Spacing.s8)
            .padding(.bottom, Spacing.s24)
        }
        .scrollDismissesKeyboard(.immediately)
        .background(DesignTokens.bg.ignoresSafeArea())
        .confirmationDialog("Delete every local book and line?", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("Delete all", role: .destructive) {
                Task { await desk.resetAllData() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Every book and line on this device is removed.")
        }
        .task { await loadExport() }
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .appFont(.caption)
            .foregroundStyle(DesignTokens.muted)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isHeader)
    }

    private func loadExport() async {
        exportFailed = false
        exporting = true
        showWait = false
        let started = Date()
        let text = await desk.exportText()
        if Date().timeIntervalSince(started) >= 0.15 {
            showWait = true
        }
        exporting = false
        if let text, !text.isEmpty {
            exportText = text
            exportFailed = false
        } else {
            exportText = nil
            exportFailed = true
        }
    }
}
