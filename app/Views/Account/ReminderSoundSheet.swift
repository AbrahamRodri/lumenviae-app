//
//  ReminderSoundSheet.swift
//  Lumen Viae
//
//  Picker for the daily reminder's notification sound. Tapping an option
//  selects it and plays a preview, so each bell can be heard before
//  choosing. All bundled sounds are public domain (pdsounds.org /
//  Wikimedia Commons) — see ReminderSound in UserSettings.swift.
//

import SwiftUI
import AVFoundation

// MARK: - ReminderSoundSheet

struct ReminderSoundSheet: View {

    @Environment(UserSettings.self) private var userSettings
    @Environment(\.dismiss) private var dismiss

    /// Preview player, retained while a sample plays
    @State private var player: AVAudioPlayer?

    /// File name of the sound currently previewing (drives the wave icon)
    @State private var previewingFile: String?

    var body: some View {
        // Scrolls so the last sound is never cut on a small phone, where
        // the header and four rows stand taller than the medium detent
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                SheetHeader(
                    kicker: "Daily reminder",
                    title: "Reminder Sound",
                    lead: "Tap a sound to hear it and make it yours."
                )

                ForEach(ReminderSound.all) { sound in
                    ReminderSoundRow(
                        sound: sound,
                        isSelected: userSettings.reminderSound == sound,
                        isPlaying: previewingFile == sound.fileName
                    ) {
                        userSettings.reminderSoundFile = sound.fileName
                        preview(sound)
                    }
                }

                SheetNote("All sounds are public domain recordings.")
            }
        }
        .sheetGround()
        .presentationDetents([.medium])
        .onDisappear {
            player?.stop()
        }
    }

    /// Plays the sound once so the user can hear it before committing.
    private func preview(_ sound: ReminderSound) {
        guard let url = Bundle.main.url(forResource: sound.fileName, withExtension: nil) else {
            return
        }

        player?.stop()
        player = try? AVAudioPlayer(contentsOf: url)
        player?.play()

        withAnimation(.easeInOut(duration: 0.2)) {
            previewingFile = sound.fileName
        }

        // Clear the playing indicator once the sample ends
        let duration = player?.duration ?? 0
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            if previewingFile == sound.fileName {
                withAnimation(.easeInOut(duration: 0.3)) {
                    previewingFile = nil
                }
            }
        }
    }
}

// MARK: - ReminderSoundRow

/// A selectable sound option, as a sheet row: glyph, name, character
/// line, and at the trailing edge the check when chosen — or, while its
/// sample plays, the animated speaker in its place.
private struct ReminderSoundRow: View {
    let sound: ReminderSound
    let isSelected: Bool
    let isPlaying: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            SheetRow(
                sound.displayName,
                detail: sound.detail,
                icon: sound.icon,
                isLit: isSelected
            ) {
                if isPlaying {
                    AppIcon("ph-speaker-high-fill", size: 16)
                        .foregroundColor(AppColors.goldLight)
                        .symbolEffect(.variableColor.iterative, options: .repeating)
                } else if isSelected {
                    SheetRowAccessoryView(accessory: .check)
                }
            }
        }
        .buttonStyle(SacredCardButtonStyle())
    }
}

// MARK: - Preview

#Preview {
    ReminderSoundSheet()
        .environment(UserSettings.shared)
}
