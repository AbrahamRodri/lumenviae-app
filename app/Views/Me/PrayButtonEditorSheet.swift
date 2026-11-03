//
//  PrayButtonEditorSheet.swift
//  Lumen Viae
//
//  The Pray button's own editor, reached from its press-and-hold tray.
//  It opens on the button itself — drawn live, with a plain sentence
//  under each gesture — so what's being chosen is never abstract:
//  change the quick tap below and the preview line changes with it.
//

import SwiftUI

struct PrayButtonEditorSheet: View {

    @Environment(UserSettings.self) private var settings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            EditorHeader(
                title: String(localized: "Pray Button", comment: "Pray button editor sheet: its title"),
                subtitle: String(localized: "What a tap starts, and what a hold shows.", comment: "Pray button editor sheet: the line under its title"),
                onDone: { dismiss() }
            )

            List {
                previewSection

                quickTapSection

                holdSections
            }
            .editorList()
        }
        .sheetGround()
    }

    // MARK: - Preview

    /// The button as it lives on the bar, with one line per gesture.
    /// Reads settings directly, so choosing below rewrites it live.
    private var previewSection: some View {
        Section {
            HStack(spacing: 22) {
                PrayNowButton()
                    .scaleEffect(0.82)
                    .frame(width: 66, height: 66)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text("TAP")
                            .font(AppFonts.labelFont(9))
                            .tracking(2)
                            .foregroundColor(AppColors.gold)
                            .frame(width: 40, alignment: .leading)

                        Text(settings.prayQuickAction.title)
                            .font(AppFonts.bodyFont(14))
                            .foregroundColor(AppColors.cream)
                    }

                    HStack(spacing: 8) {
                        Text("HOLD")
                            .font(AppFonts.labelFont(9))
                            .tracking(2)
                            .foregroundColor(AppColors.gold)
                            .frame(width: 40, alignment: .leading)

                        Text(holdSummary)
                            .font(AppFonts.bodyFont(14))
                            .foregroundColor(AppColors.cream)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, SheetMetrics.gutter)
            .padding(.vertical, 10)
            .editorListRow()
        }
    }

    private var holdSummary: String {
        let count = settings.prayTrayShortcuts.count
        switch count {
        case 0:
            return String(
                localized: "Opens an empty menu",
                comment: "Pray button editor: what holding the button does when its menu holds no devotion"
            )
        default:
            return String(
                localized: "Opens a menu of \(count) devotions",
                comment: "Pray button editor: what holding the button does, with the number of devotions in its menu"
            )
        }
    }

    // MARK: - Quick tap

    private var quickTapSection: some View {
        Section {
            ForEach(PrayerShortcut.allCases) { shortcut in
                Button {
                    settings.prayQuickActionRaw = shortcut.rawValue
                } label: {
                    SheetRow(
                        shortcut.title,
                        detail: shortcut.subtitle,
                        icon: shortcut.icon,
                        isLit: settings.prayQuickAction == shortcut,
                        detailLineLimit: nil
                    ) {
                        if settings.prayQuickAction == shortcut {
                            AppIcon("ph-check-circle-fill", size: 20)
                                .foregroundColor(AppColors.goldLight)
                        } else {
                            Circle()
                                .strokeBorder(AppColors.gold.opacity(0.3), lineWidth: 1.2)
                                .frame(width: 20, height: 20)
                        }
                    }
                }
                .buttonStyle(SacredCardButtonStyle())
                .editorListRow()
                .accessibilityAddTraits(settings.prayQuickAction == shortcut ? .isSelected : [])
            }
        } header: {
            EditorSectionHeader(String(localized: "When you tap", comment: "Pray button editor: section heading over the devotion a single tap starts"))
        } footer: {
            EditorSectionFooter(
                String(localized: "A tap on Pray starts this one, with no menu on the way.", comment: "Pray button editor: note under the tap section")
            )
        }
    }

    // MARK: - Press and hold

    @ViewBuilder
    private var holdSections: some View {
        let enabled = settings.prayTrayShortcuts
        let available = PrayerShortcut.allCases.filter { !enabled.contains($0) }

        Section {
            ForEach(enabled, id: \.keptRowID) { shortcut in
                EditorRow(
                    icon: shortcut.icon,
                    title: shortcut.title,
                    detail: shortcut.subtitle
                ) {
                    EditorRemoveButton(
                        label: String(localized: "Remove \(shortcut.title) from the menu", comment: "VoiceOver, Pray button editor: button taking a devotion out of the hold menu")
                    ) {
                        withAnimation(Motion.settle) {
                            settings.setPrayTray(enabled.filter { $0 != shortcut })
                        }
                    }
                }
            }
            .onMove { from, to in
                var items = enabled
                items.move(fromOffsets: from, toOffset: to)
                settings.setPrayTray(items)
            }
        } header: {
            EditorSectionHeader(String(localized: "When you hold", comment: "Pray button editor: section heading over the menu a press and hold opens"))
        } footer: {
            EditorSectionFooter(
                String(
                    localized: "Press and hold the button to open this menu. Drag to set its order.",
                    comment: "Pray button editor: note under the hold menu section"
                )
            )
        }

        if !available.isEmpty {
            Section {
                ForEach(available, id: \.addRowID) { shortcut in
                    EditorAddRow(
                        icon: shortcut.icon,
                        title: shortcut.title,
                        detail: shortcut.subtitle,
                        accessibilityLabel: String(localized: "Add \(shortcut.title) to the menu", comment: "VoiceOver, Pray button editor: row adding a devotion to the hold menu")
                    ) {
                        withAnimation(Motion.settle) {
                            settings.setPrayTray(enabled + [shortcut])
                        }
                    }
                }
            } header: {
                EditorSectionHeader(String(localized: "Add to the menu", comment: "Pray button editor: section heading over devotions that can be added to the hold menu"))
            }
        }
    }
}

// MARK: - Preview

#Preview {
    PrayButtonEditorSheet()
        .environment(UserSettings.shared)
}
