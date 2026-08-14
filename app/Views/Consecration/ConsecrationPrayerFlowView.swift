//
//  ConsecrationPrayerFlowView.swift
//  Lumen Viae
//
//  Displays prayers one at a time in an immersive, full-screen view.
//  After the last prayer, navigates to the meditation view.
//

import SwiftUI
import AVFoundation

// MARK: - ConsecrationPrayerFlowView

struct ConsecrationPrayerFlowView: View {

    // MARK: - Properties

    @Binding var path: NavigationPath

    let dayNumber: Int

    /// The prayer to open on — the day overview lists them, and a tap
    /// there should land on the prayer that was tapped.
    init(path: Binding<NavigationPath>, dayNumber: Int, startIndex: Int = 0) {
        self._path = path
        self.dayNumber = dayNumber
        self._currentIndex = State(initialValue: startIndex)
    }

    // MARK: - Environment

    @Environment(UserSettings.self) private var settings

    // MARK: - State

    @State private var currentIndex: Int
    @State private var opacity: Double = 1.0
    @State private var cachedAudioUrls: [String: String] = [:]

    private let audio = AudioService.shared

    // MARK: - Computed Properties

    private var prayers: [ConsecrationPrayer] {
        guard let phase = ConsecrationPhase.phase(for: dayNumber) else { return [] }
        return ConsecrationData.prayers(for: phase, language: settings.prayerLanguage)
    }

    private var currentPrayer: ConsecrationPrayer? {
        guard currentIndex < prayers.count else { return nil }
        return prayers[currentIndex]
    }

    private var isLastPrayer: Bool {
        currentIndex >= prayers.count - 1
    }

    private var phase: ConsecrationPhase? {
        ConsecrationPhase.phase(for: dayNumber)
    }

    // MARK: - Audio

    private func loadAudioIfAvailable() {
        guard let prayer = currentPrayer, prayer.hasAudio else { return }
        Task {
            // Downloaded chants play offline and skip the presign round-trip
            if let local = OfflineContentService.shared.localPrayerAudioURL(prayerId: prayer.id) {
                await audio.loadAudio(
                    from: local.absoluteString,
                    title: prayer.title,
                    subtitle: "33-Day Consecration"
                )
                return
            }

            do {
                let presignedUrl: String
                if let cached = cachedAudioUrls[prayer.id] {
                    presignedUrl = cached
                } else {
                    presignedUrl = try await APIService.shared.fetchPrayerAudioUrl(prayerId: prayer.id)
                    cachedAudioUrls[prayer.id] = presignedUrl
                }
                await audio.loadAudio(
                    from: presignedUrl,
                    title: prayer.title,
                    subtitle: "33-Day Consecration"
                )
            } catch {
                #if DEBUG
                print("ConsecrationPrayerFlowView: Failed to load audio: \(error)")
                #endif
            }
        }
    }

    @ViewBuilder
    private func audioPlayer() -> some View {
        HStack(spacing: 16) {
            // Play/Pause button
            Button {
                audio.togglePlayback()
            } label: {
                AppIcon(audio.isPlaying ? "ph-pause-circle-fill" : "ph-play-circle-fill", size: 44)
                    .font(.system(size: 36))
                    .foregroundColor(AppColors.gold)
            }
            .disabled(audio.isLoading)

            // Progress slider
            VStack(alignment: .leading, spacing: 4) {
                Slider(
                    value: Binding(
                        get: { audio.currentTime },
                        set: { audio.seek(to: $0) }
                    ),
                    in: 0...(audio.duration > 0 ? audio.duration : 1)
                )
                .tint(AppColors.gold)

                HStack {
                    Text(formatTime(audio.currentTime))
                    Spacer()
                    Text(formatTime(audio.duration))
                }
                .font(AppFonts.bodyFont(11))
                .foregroundColor(AppColors.textSecondary)
            }
        }
        .padding(16)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func formatTime(_ seconds: Double) -> String {
        guard seconds > 0, !seconds.isNaN, !seconds.isInfinite else { return "0:00" }
        let m = Int(seconds) / 60
        let s = Int(seconds) % 60
        return "\(m):\(String(format: "%02d", s))"
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background - use app gradient
            ConsecrationPhaseBackground(phase: phase)
                .ignoresSafeArea()

            // Content
            VStack(spacing: 0) {
                // Top Bar with close button and progress
                topBar
                    .padding(.top, 8)

                // Prayer Content
                if let prayer = currentPrayer {
                    prayerContent(prayer)
                        .opacity(opacity)
                }

                Spacer(minLength: 0)

                // Bottom Controls
                bottomControls
                    .padding(.bottom, 16)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            // currentIndex is intentionally NOT reset here: onAppear also
            // fires when popping back from the meditation view, and the
            // user should return to the prayer they left, not prayer 1.
            opacity = 1.0
            loadAudioIfAvailable()
        }
        .onDisappear {
            audio.reset()
            // Hand the audio session back so other apps' audio can resume
            audio.deactivateSession()
        }
        .onChange(of: currentIndex) {
            audio.reset()
            loadAudioIfAvailable()
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(alignment: .center) {
            // Close Button
            Button {
                // A second tap during the pop animation would call
                // removeLast() on an empty path and crash
                if !path.isEmpty { path.removeLast() }
            } label: {
                AppIcon("ph-x", size: 16)
                    .foregroundColor(AppColors.cream.opacity(0.7))
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(AppColors.cardBackground)
                    )
                    // 44pt hit target around the 36pt visual circle
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }

            Spacer()

            // Progress Indicator
            progressIndicator

            Spacer()

            // Spacer for symmetry
            Color.clear
                .frame(width: 44, height: 44)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Progress Indicator

    private var progressIndicator: some View {
        VStack(spacing: 6) {
            // Day indicator
            Text("DAY \(dayNumber)")
                .font(AppFonts.bodyFont(10))
                .tracking(2)
                .foregroundColor(AppColors.textSecondary)

            // Progress dots
            HStack(spacing: 6) {
                ForEach(0..<prayers.count, id: \.self) { index in
                    Capsule()
                        .fill(index <= currentIndex ? AppColors.gold : AppColors.cardBackground)
                        .frame(width: index == currentIndex ? 20 : 8, height: 4)
                        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentIndex)
                }
            }
        }
    }

    // MARK: - Prayer Content

    private func prayerContent(_ prayer: ConsecrationPrayer) -> some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 40)
                        .id("top")

                    // Prayer Title Section
                    VStack(spacing: 12) {
                        // Latin title — skipped when it IS the main title
                        // (Latin display modes), which would duplicate it
                        if let latinTitle = prayer.latinTitle,
                           latinTitle.caseInsensitiveCompare(prayer.title) != .orderedSame {
                            Text(latinTitle.uppercased())
                                .font(AppFonts.bodyFont(11))
                                .tracking(3)
                                .foregroundColor(AppColors.gold)
                        }

                        // Main title
                        Text(prayer.title)
                            .font(AppFonts.headlineFont(26))
                            .foregroundColor(AppColors.cream)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }

                    // Decorative divider
                    HStack(spacing: 12) {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [.clear, AppColors.gold.opacity(0.5)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(height: 1)

                        AppIcon("ph-sparkle", size: 10)
                            .foregroundColor(AppColors.gold.opacity(0.6))

                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [AppColors.gold.opacity(0.5), .clear],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(height: 1)
                    }
                    .padding(.horizontal, 50)
                    .padding(.vertical, 24)

                    // Audio Player (only shown when audio is available)
                    if prayer.hasAudio {
                        audioPlayer()
                            .padding(.horizontal, 28)
                            .padding(.bottom, 24)
                    }

                    // Every prayer reads down the left edge, whatever the
                    // display language. Centering single-language text put
                    // the same prayer on two different designs depending on
                    // a setting — and centered prose, which most of these
                    // are, is the harder of the two to read.
                    PrayerText(
                        content: prayer.content,
                        size: 18,
                        alignment: .leading
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 28)

                    // Bottom padding for scroll
                    Spacer()
                        .frame(height: 120)
                }
            }
            .onChange(of: currentIndex) {
                proxy.scrollTo("top", anchor: .top)
            }
        }
        .mask(
            VStack(spacing: 0) {
                // Top fade
                LinearGradient(
                    colors: [.clear, .black],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 30)

                Rectangle()
                    .fill(Color.black)

                // Bottom fade
                LinearGradient(
                    colors: [.black, .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 80)
            }
        )
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        VStack(spacing: 16) {
            // Prayer counter
            Text("\(currentIndex + 1) of \(prayers.count)")
                .font(AppFonts.bodyFont(12))
                .foregroundColor(AppColors.textSecondary)

            // Continue Button
            Button {
                if isLastPrayer {
                    // Navigate to meditation
                    path.append(ConsecrationRoute.meditation(dayNumber: dayNumber))
                } else {
                    // Animate transition to next prayer
                    withAnimation(.easeOut(duration: 0.15)) {
                        opacity = 0
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        // Clamp: rapid taps queue multiple increments, and
                        // running past the last prayer blanks the screen
                        currentIndex = min(currentIndex + 1, prayers.count - 1)
                        withAnimation(.easeIn(duration: 0.2)) {
                            opacity = 1
                        }
                    }
                }
            } label: {
                HStack(spacing: 10) {
                    Text(isLastPrayer ? "Continue to Meditation" : "Continue")
                        .font(AppFonts.headlineFont(16))

                    AppIcon(isLastPrayer ? "ph-book-open-fill" : "ph-arrow-right", size: 15)
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(AppColors.background)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    LinearGradient(
                        colors: [AppColors.gold, AppColors.goldLight],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 24)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ConsecrationPrayerFlowView(path: .constant(NavigationPath()), dayNumber: 1)
            .environment(ConsecrationViewModel())
            .environment(UserSettings.shared)
    }
}
