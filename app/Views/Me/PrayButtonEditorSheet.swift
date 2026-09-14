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
                title: "Pray Button",
                subtitle: "What a tap begins, and what a hold offers.",
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
        case 0:  return "Opens an empty menu"
        case 1:  return "Opens a menu of 1 devotion"
        default: return "Opens a menu of \(count) devotions"
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
            EditorSectionHeader("When you tap")
        } footer: {
            EditorSectionFooter("One tap starts this straight away — no menus on the way.")
        }
    }

    // MARK: - Press and hold

    @ViewBuilder
    private var holdSections: some View {
        let enabled = settings.prayTrayShortcuts
        let available = PrayerShortcut.allCases.filter { !enabled.contains($0) }

        Section {
            ForEach(enabled) { shortcut in
                EditorRow(
                    icon: shortcut.icon,
                    title: shortcut.title,
                    detail: shortcut.subtitle
                ) {
                    EditorRemoveButton(label: "Remove \(shortcut.title) from the menu") {
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
            EditorSectionHeader("When you hold")
        } footer: {
            EditorSectionFooter("Press and hold the button to open this menu. Drag to set its order.")
        }

        if !available.isEmpty {
            Section {
                ForEach(available) { shortcut in
                    EditorAddRow(
                        icon: shortcut.icon,
                        title: shortcut.title,
                        detail: shortcut.subtitle,
                        accessibilityLabel: "Add \(shortcut.title) to the menu"
                    ) {
                        withAnimation(Motion.settle) {
                            settings.setPrayTray(enabled + [shortcut])
                        }
                    }
                }
            } header: {
                EditorSectionHeader("Add to the menu")
            }
        }
    }
}

// MARK: - Preview

#Preview {
    PrayButtonEditorSheet()
        .environment(UserSettings.shared)
}
