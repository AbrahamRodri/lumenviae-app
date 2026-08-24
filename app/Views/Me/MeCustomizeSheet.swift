//
//  MeCustomizeSheet.swift
//  Lumen Viae
//
//  MePageEditorSheet — the Me page's own editor: the name at the top,
//  the cards on the page, and the Rule of Prayer. The Pray button has
//  its own editor (PrayButtonEditorSheet), reached from its tray, so
//  each editor answers one question: "what is on my page?" here,
//  "what does the button do?" there.
//
//  Interaction grammar is the platform's own (Apple Health's editable
//  Summary): rows are added by tap, removed by their ✕, and reordered
//  by dragging the grabber. Every section says beneath it what the
//  choice does. Removing a card hides a view, never data.
//
//  The shared editor furniture (rows, headers) lives here and is reused
//  by the Pray button editor.
//

import SwiftUI

struct MePageEditorSheet: View {

    @Environment(UserSettings.self) private var settings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            AppColors.appGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                EditorHeader(
                    title: "Edit Page",
                    subtitle: "Choose what appears, and in what order.",
                    onDone: { dismiss() }
                )

                List {
                    nameSection

                    pageSections

                    ruleSections
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .environment(\.editMode, .constant(.active))
            }
        }
    }

    // MARK: - Name

    private var nameSection: some View {
        Section {
            TextField(
                "Faithful Pilgrim",
                text: Binding(
                    get: { settings.displayName },
                    set: { settings.displayName = $0 }
                )
            )
            .font(AppFonts.bodyFont(16))
            .foregroundColor(AppColors.cream)
            .tint(AppColors.gold)
            .submitLabel(.done)
            .listRowBackground(AppColors.cardBackground)
        } header: {
            EditorSectionHeader("Your name")
        } footer: {
            EditorSectionFooter("Shown at the top of your page.")
        }
    }

    // MARK: - Page sections

    @ViewBuilder
    private var pageSections: some View {
        let enabled = settings.meWidgets
        let available = MeWidget.allCases.filter { !enabled.contains($0) }

        Section {
            ForEach(enabled) { widget in
                EditorRow(
                    icon: widget.icon,
                    title: widget.title,
                    detail: widget.detail
                ) {
                    EditorRemoveButton(label: "Remove \(widget.title)") {
                        withAnimation {
                            settings.setMeWidgets(enabled.filter { $0 != widget })
                        }
                    }
                }
            }
            .onMove { from, to in
                var items = enabled
                items.move(fromOffsets: from, toOffset: to)
                settings.setMeWidgets(items)
            }
        } header: {
            EditorSectionHeader("On your page")
        } footer: {
            EditorSectionFooter("Drag to reorder. Removing a card never deletes anything — your streak keeps counting, your journal keeps saving.")
        }

        if !available.isEmpty {
            Section {
                ForEach(available) { widget in
                    EditorAddRow(
                        icon: widget.icon,
                        title: widget.title,
                        detail: widget.detail,
                        accessibilityLabel: "Add \(widget.title) to your page"
                    ) {
                        withAnimation {
                            settings.setMeWidgets(enabled + [widget])
                        }
                    }
                }
            } header: {
                EditorSectionHeader("Add to your page")
            } footer: {
                EditorSectionFooter("Tap to put a card back on your page.")
            }
        }
    }

    // MARK: - Rule of Prayer

    @ViewBuilder
    private var ruleSections: some View {
        let enabled = settings.ruleItems
        let available = PrayerShortcut.allCases.filter { $0.isRuleEligible && !enabled.contains($0) }

        Section {
            ForEach(enabled) { item in
                EditorRow(
                    icon: item.icon,
                    title: item.title,
                    detail: nil
                ) {
                    EditorRemoveButton(label: "Remove \(item.title) from your rule") {
                        withAnimation {
                            settings.setRuleItems(enabled.filter { $0 != item })
                        }
                    }
                }
            }
            .onMove { from, to in
                var items = enabled
                items.move(fromOffsets: from, toOffset: to)
                settings.setRuleItems(items)
            }
        } header: {
            EditorSectionHeader("Your rule of prayer")
        } footer: {
            EditorSectionFooter("The devotions on your daily checklist. Each day starts fresh — yesterday is never held against you.")
        }

        if !available.isEmpty {
            Section {
                ForEach(available) { item in
                    EditorAddRow(
                        icon: item.icon,
                        title: item.title,
                        detail: item.subtitle,
                        accessibilityLabel: "Add \(item.title) to your rule"
                    ) {
                        withAnimation {
                            settings.setRuleItems(enabled + [item])
                        }
                    }
                }
            } header: {
                EditorSectionHeader("Add to your rule")
            }
        }
    }
}

// MARK: - Shared editor furniture

/// Sheet header used by both editors: grab handle, a plain title, one
/// line saying what the sheet edits, and Done.
struct EditorHeader: View {
    let title: String
    let subtitle: String
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Capsule()
                .fill(AppColors.gold.opacity(0.3))
                .frame(width: 40, height: 4)
                .padding(.top, 12)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(AppFonts.headlineFont(24))
                        .foregroundColor(AppColors.cream)

                    Text(subtitle)
                        .font(AppFonts.italicFont(13))
                        .foregroundColor(AppColors.textSecondary)
                }

                Spacer()

                QuietGoldButton(
                    title: "Done",
                    size: 10,
                    color: AppColors.gold,
                    horizontalPadding: 0,
                    action: onDone
                )
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
        }
    }
}

struct EditorSectionHeader: View {
    let title: String

    init(_ title: String) { self.title = title }

    var body: some View {
        Text(title.uppercased())
            .font(AppFonts.labelFont(10))
            .tracking(2)
            .foregroundColor(AppColors.gold.opacity(0.7))
    }
}

struct EditorSectionFooter: View {
    let text: String

    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(AppFonts.italicFont(12))
            .foregroundColor(AppColors.textSecondary)
    }
}

/// A row already in a list: icon, name, its remove control. The move
/// grabber is the List's own, supplied by edit mode.
struct EditorRow<Accessory: View>: View {
    let icon: String
    let title: String
    let detail: String?
    @ViewBuilder let accessory: Accessory

    var body: some View {
        HStack(spacing: 14) {
            AppIcon(icon, size: 17)
                .foregroundColor(AppColors.gold)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppFonts.bodyFont(15))
                    .foregroundColor(AppColors.cream)

                if let detail {
                    Text(detail)
                        .font(AppFonts.bodyFont(11))
                        .foregroundColor(AppColors.textSecondary)
                }
            }

            Spacer()

            accessory
        }
        .listRowBackground(AppColors.cardBackground)
    }
}

/// A row not yet in its list. The whole row adds it.
struct EditorAddRow: View {
    let icon: String
    let title: String
    let detail: String?
    let accessibilityLabel: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                AppIcon(icon, size: 17)
                    .foregroundColor(AppColors.gold.opacity(0.6))
                    .frame(width: 22)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppFonts.bodyFont(15))
                        .foregroundColor(AppColors.cream.opacity(0.85))

                    if let detail {
                        Text(detail)
                            .font(AppFonts.bodyFont(11))
                            .foregroundColor(AppColors.textSecondary)
                    }
                }

                Spacer()

                AppIcon("ph-caret-up", size: 13)
                    .foregroundColor(AppColors.gold.opacity(0.5))
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowBackground(AppColors.cardBackground.opacity(0.6))
        .accessibilityLabel(accessibilityLabel)
    }
}

struct EditorRemoveButton: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            AppIcon("ph-x-circle", size: 19)
                .foregroundColor(AppColors.textSecondary.opacity(0.8))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

// MARK: - Preview

#Preview {
    MePageEditorSheet()
        .environment(UserSettings.shared)
}
