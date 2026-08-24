//
//  PrayShortcutTray.swift
//  Lumen Viae
//
//  The Pray button's press-and-hold tray: the user's chosen devotions,
//  each one motion away — the Me page in miniature, under the thumb.
//
//  Like the prayer flow's track menu, it is a tray of the app's own
//  making rather than a system context menu, which would land on the
//  gold-and-candlelight bar as a piece of another app.
//
//  Rows dismiss first and act second (the same pendingHandoff pattern
//  the prayer tray uses) so an act that presents its own sheet — the
//  Mass, the Office — never tries to present into a dismissal.
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
    static let arrangeRowHeight: CGFloat = 48
    static let topPadding: CGFloat = 26
    static let bottomPadding: CGFloat = 20

    /// The tray's natural height for its detent — rows plus the arrange
    /// row, so it never opens onto empty card.
    static func height(for settings: UserSettings) -> CGFloat {
        CGFloat(settings.prayTrayShortcuts.count) * rowHeight
            + arrangeRowHeight + topPadding + bottomPadding
    }

    var body: some View {
        ZStack {
            AppColors.appGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                Capsule()
                    .fill(AppColors.gold.opacity(0.3))
                    .frame(width: 40, height: 4)
                    .padding(.top, 12)
                    .padding(.bottom, 10)

                ForEach(settings.prayTrayShortcuts) { shortcut in
                    Button {
                        pendingShortcut = shortcut
                        dismiss()
                    } label: {
                        HStack(spacing: 16) {
                            AppIcon(shortcut.icon, size: 19)
                                .foregroundColor(AppColors.gold)
                                .frame(width: 26)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(shortcut.title)
                                    .font(AppFonts.bodyFont(16))
                                    .foregroundColor(AppColors.cream)

                                Text(subtitle(for: shortcut))
                                    .font(AppFonts.bodyFont(12))
                                    .foregroundColor(AppColors.textSecondary)
                            }

                            Spacer()
                        }
                        .padding(.horizontal, 24)
                        .frame(height: Self.rowHeight)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }

                // The tray's own door to its editor — edited in place,
                // not in buried settings
                Button {
                    pendingArrange = true
                    dismiss()
                } label: {
                    HStack(spacing: 10) {
                        AppIcon("ph-pencil-simple", size: 13)

                        Text("EDIT THIS MENU")
                            .font(AppFonts.labelFont(10))
                            .tracking(2)
                    }
                    .foregroundColor(AppColors.gold.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .frame(height: Self.arrangeRowHeight)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Spacer(minLength: 0)
            }
        }
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
            .presentationDetents([.height(PrayShortcutTray.height(for: UserSettings.shared))])
        }
}
