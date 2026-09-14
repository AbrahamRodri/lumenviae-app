//
//  PrayShortcutTray.swift
//  Lumen Viae
//
//  The Pray button's press-and-hold tray: the user's chosen devotions,
//  each one motion away, under the thumb.
//
//  Set in the app's one sheet grammar (`DesignSystem/SheetChrome.swift`),
//  taken from the consecration day's index: a kicker and a title with
//  room above them, then a ruled list of glyph, name, italic line, and
//  caret. The tray used to open on a hand-drawn grabber twelve points
//  from its top edge with the first row pressed up beneath it, and no
//  heading at all.
//
//  The row the Pray button's own tap runs is lit, and says so (QUICK
//  TAP), the way the index lights the prayer you are on. It is the one
//  thing about this menu nobody could otherwise see.
//
//  Rows dismiss first and act second (the same pendingHandoff pattern
//  the prayer tray uses) so an act that presents its own sheet — the
//  Mass, the Office — never tries to present into a dismissal.
//
//  The tray opens as tall as it measures (`fittedSheetDetent`); its host
//  sets no detent of its own.
//

import SwiftUI

struct PrayShortcutTray: View {

    /// The act to run once the tray has finished leaving, handed to the
    /// host that owns the sheet.
    @Binding var pendingShortcut: PrayerShortcut?

    /// Set when the user asks to edit this menu; the host opens the
    /// Pray button editor once the tray has left.
    @Binding var pendingArrange: Bool

    @Environment(UserSettings.self) private var settings
    @Environment(\.dismiss) private var dismiss

    static let rowHeight: CGFloat = 64
    static let arrangeRowHeight: CGFloat = 56
    static let bottomPadding: CGFloat = 14

    /// A first guess at the tray's height, for the frame before it has
    /// been measured: a header, the rows, and the arrange row
    private var estimatedHeight: CGFloat {
        100
            + CGFloat(settings.prayTrayShortcuts.count) * Self.rowHeight
            + Self.arrangeRowHeight
            + Self.bottomPadding
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SheetHeader(
                kicker: Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day()),
                title: "Your Devotions"
            )

            ForEach(Array(settings.prayTrayShortcuts.enumerated()), id: \.element) { index, shortcut in
                row(shortcut, isQuickTap: shortcut == settings.prayQuickAction)
                    // The rows arrive one after another as the tray
                    // rises: the Pray button's second gesture should
                    // feel as alive as its first
                    .devotionalEntrance(delay: 0.05 + 0.05 * Double(index), drift: 8)
            }

            arrangeRow
                .devotionalEntrance(
                    delay: 0.05 + 0.05 * Double(settings.prayTrayShortcuts.count),
                    drift: 8
                )
        }
        .padding(.bottom, Self.bottomPadding)
        .fittedSheetDetent(estimate: estimatedHeight)
        .sheetGround()
    }

    // MARK: - Rows

    private func row(_ shortcut: PrayerShortcut, isQuickTap: Bool) -> some View {
        Button {
            pendingShortcut = shortcut
            dismiss()
        } label: {
            SheetRow(
                shortcut.title,
                detail: subtitle(for: shortcut),
                icon: shortcut.icon,
                accessory: isQuickTap ? .label("Quick tap") : .caret,
                isLit: isQuickTap
            )
            .frame(height: Self.rowHeight)
        }
        .buttonStyle(SacredCardButtonStyle())
        .accessibilityLabel(shortcut.title)
        .accessibilityHint(isQuickTap ? "Also what a tap on the Pray button does" : "")
    }

    /// The tray's own door to its editor — edited in place, not in
    /// buried settings
    private var arrangeRow: some View {
        Button {
            pendingArrange = true
            dismiss()
        } label: {
            HStack(spacing: 8) {
                AppIcon("ph-pencil-simple", size: 12)

                Text("EDIT THIS MENU")
                    .font(AppFonts.labelFont(10))
                    .tracking(2)
            }
            .foregroundColor(AppColors.gold.opacity(0.75))
            .frame(maxWidth: .infinity)
            .frame(height: Self.arrangeRowHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(QuietGlyphButtonStyle())
    }

    /// The Rosary's line names the day's mysteries; the rest carry
    /// their standing line.
    private func subtitle(for shortcut: PrayerShortcut) -> String {
        switch shortcut {
        case .todaysRosary:
            return ScheduleService.categoryForToday().devotionTitle
        default:
            return shortcut.subtitle
        }
    }
}

// MARK: - Preview

#Preview {
    Color.black
        .sheet(isPresented: .constant(true)) {
            PrayShortcutTray(
                pendingShortcut: .constant(nil),
                pendingArrange: .constant(false)
            )
            .environment(UserSettings.shared)
        }
}
