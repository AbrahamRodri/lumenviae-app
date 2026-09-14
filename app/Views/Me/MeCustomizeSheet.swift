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
                        withAnimation(Motion.settle) {
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
                        withAnimation(Motion.settle) {
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

    private var ruleSections: some View {
        RuleEditorSections()
    }
}

// MARK: - RuleEditorSheet

/// The Rule of Prayer's own editor: which devotions are on the daily
/// checklist, and in what order. Opened from Settings and from the
/// Chapel's empty-rule invitations — the Chapel page itself is arranged
/// in place and needs no sheet.
struct RuleEditorSheet: View {

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            EditorHeader(
                title: "Rule of Prayer",
                subtitle: "The devotions you mean to offer each day.",
                onDone: { dismiss() }
            )

            List {
                RuleEditorSections()
            }
            .editorList()
        }
        .sheetGround()
    }
}

// MARK: - RuleEditorSections

/// The rule's list sections, shared by the page editor and the
/// standalone rule sheet.
struct RuleEditorSections: View {

    @Environment(UserSettings.self) private var settings

    var body: some View {
        let enabled = settings.ruleItems
        let available = PrayerShortcut.allCases.filter { $0.isRuleEligible && !enabled.contains($0) }

        Section {
            ForEach(enabled) { item in
                EditorRow(
                    icon: item.icon,
                    title: item.actName,
                    detail: nil
                ) {
                    EditorRemoveButton(label: "Remove \(item.actName) from your rule") {
                        withAnimation(Motion.settle) {
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
            EditorSectionFooter("The devotions on your daily checklist. While a consecration is under way it joins the rule on its own. Each day starts fresh — yesterday is never held against you.")
        }

        if !available.isEmpty {
            Section {
                ForEach(available) { item in
                    EditorAddRow(
                        icon: item.icon,
                        title: item.actName,
                        detail: item.subtitle,
                        accessibilityLabel: "Add \(item.actName) to your rule"
                    ) {
                        withAnimation(Motion.settle) {
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

/// Sheet header used by the editors and the chant sheet: a sheet's
/// heading, one line saying what the sheet edits, and Done. The drag
/// indicator is the system's, from `sheetGround()` at the sheet's root.
struct EditorHeader: View {
    let title: String
    let subtitle: String
    let onDone: () -> Void

    var body: some View {
        SheetHeader(title: title, lead: subtitle) {
            SheetHeaderAction(title: "Done", action: onDone)
        }
    }
}

extension View {
    /// An editor's list, set as a sheet's ruled rows on the gradient.
    /// Grouped rather than plain: a plain list pins its section headers,
    /// and a pinned header lays the system's own bar across the page.
    /// Always in edit mode, so the kept rows carry their grabbers.
    func editorList() -> some View {
        self
            .listStyle(.grouped)
            .scrollContentBackground(.hidden)
            .environment(\.editMode, .constant(.active))
    }

    /// One row of an editor's list: full width, no fill, and no system
    /// separator — `SheetRow` keeps the gutter and draws its own rule.
    func editorListRow() -> some View {
        self
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
    }
}

/// A section's name, in `SheetSectionLabel`'s type. Drawn here rather
/// than reused because a list header takes its margins from its row
/// insets, not from padding of its own.
struct EditorSectionHeader: View {
    let title: String

    init(_ title: String) { self.title = title }

    var body: some View {
        Text(title.uppercased())
            .font(AppFonts.labelFont(9))
            .tracking(2.5)
            .foregroundColor(AppColors.gold.opacity(0.75))
            .frame(maxWidth: .infinity, alignment: .leading)
            .listRowInsets(EdgeInsets(
                top: 20,
                leading: SheetMetrics.gutter,
                bottom: 8,
                trailing: SheetMetrics.gutter
            ))
            .accessibilityAddTraits(.isHeader)
    }
}

/// A section's note, in `SheetNote`'s type
struct EditorSectionFooter: View {
    let text: String

    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(AppFonts.italicFont(13))
            .foregroundColor(AppColors.textSecondary)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .listRowInsets(EdgeInsets(
                top: 10,
                leading: SheetMetrics.gutter,
                bottom: 6,
                trailing: SheetMetrics.gutter
            ))
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
        SheetRow(title, detail: detail, icon: icon, detailLineLimit: nil) {
            accessory
        }
        .editorListRow()
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
            SheetRow(title, detail: detail, icon: icon, detailLineLimit: nil) {
                AppIcon("ph-caret-up", size: 13)
                    .foregroundColor(AppColors.gold.opacity(0.5))
                    .accessibilityHidden(true)
            }
        }
        .buttonStyle(SacredCardButtonStyle())
        .editorListRow()
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
