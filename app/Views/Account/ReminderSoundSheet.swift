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
        ZStack {
            AppColors.appGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Handle
                Capsule()
                    .fill(AppColors.gold.opacity(0.3))
                    .frame(width: 40, height: 4)
                    .padding(.top, 12)

                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 10) {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 32))
                            .foregroundColor(AppColors.gold)

                        Text("Reminder Sound")
                            .font(AppFonts.headlineFont(22))
                            .foregroundColor(AppColors.cream)

                        Text("Tap a sound to hear it and make it yours.")
                            .font(AppFonts.italicFont(14))
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .padding(.top, 28)

                    // Sound options
                    VStack(spacing: 0) {
                        ForEach(Array(ReminderSound.all.enumerated()), id: \.element.id) { index, sound in
                            ReminderSoundRow(
                                sound: sound,
                                isSelected: userSettings.reminderSound == sound,
                                isPlaying: previewingFile == sound.fileName
                            ) {
                                userSettings.reminderSoundFile = sound.fileName
                                preview(sound)
                            }

                            if index < ReminderSound.all.count - 1 {
                                Divider()
                                    .background(AppColors.gold.opacity(0.2))
                            }
                        }
                    }
                    .background(AppColors.cardBackground)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(AppColors.gold.opacity(0.15), lineWidth: 0.5)
                    )
                    .padding(.horizontal, 20)

                    Text("All sounds are public domain recordings.")
                        .font(AppFonts.bodyFont(12))
                        .foregroundColor(AppColors.textSecondary)

                    Spacer()
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
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

/// A selectable sound option: name, character line, and a state icon —
/// gold checkmark when chosen, animated speaker while previewing.
private struct ReminderSoundRow: View {
    let sound: ReminderSound
    let isSelected: Bool
    let isPlaying: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: sound.icon)
                    .font(.system(size: 16))
                    .foregroundColor(isSelected ? AppColors.gold : AppColors.textSecondary)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(sound.displayName)
                        .font(AppFonts.headlineFont(16))
                        .foregroundColor(AppColors.cream)

                    Text(sound.detail)
                        .font(AppFonts.bodyFont(13))
                        .foregroundColor(AppColors.textSecondary)
                }

                Spacer()

                if isPlaying {
                    Image(systemName: "speaker.wave.3.fill")
                        .font(.system(size: 16))
                        .foregroundColor(AppColors.goldLight)
                        .symbolEffect(.variableColor.iterative, options: .repeating)
                } else if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(AppColors.gold)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    ReminderSoundSheet()
        .environment(UserSettings.shared)
}
