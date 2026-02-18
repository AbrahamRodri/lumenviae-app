//
//  OnboardingView.swift
//  Lumen Viae
//
//  First-run tutorial shown once on initial launch.
//  Tracked via @AppStorage so it never appears again after completion.
//
//  Flow (3 slides):
//    Slide 1 (Welcome) → Slide 2 (How it works) → Slide 3 (Choice)
//      • "Begin Prayer"                    → onComplete() → ContentView
//      • "Methods of Praying the Rosary"   → sheet (RosaryMethodsView)
//

import SwiftUI

// MARK: - OnboardingView

struct OnboardingView: View {

    var onComplete: () -> Void

    @State private var currentPage = 0
    @State private var showMethodsSheet = false

    private let totalPages = 3

    var body: some View {
        ZStack {
            AppColors.appGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Page indicator dots
                HStack(spacing: 8) {
                    ForEach(0..<totalPages, id: \.self) { index in
                        Capsule()
                            .fill(index == currentPage ? AppColors.gold : AppColors.textSecondary.opacity(0.4))
                            .frame(width: index == currentPage ? 20 : 8, height: 8)
                            .animation(.easeInOut(duration: 0.25), value: currentPage)
                    }
                }
                .padding(.top, 60)
                .padding(.bottom, 8)

                // Slides
                TabView(selection: $currentPage) {
                    slide1.tag(0)
                    slide2.tag(1)
                    slide3.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentPage)
            }
        }
        .sheet(isPresented: $showMethodsSheet) {
            RosaryMethodsView()
        }
    }

    // MARK: - Slide 1: What the App Is

    private var slide1: some View {
        OnboardingSlideLayout(
            icon: "rosette",
            iconIsGradient: true,
            title: "Your Rosary Companion",
            content: {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Lumen Viae is a Rosary helper — not an audio walkthrough of the entire prayer.")
                        .font(AppFonts.headlineFont(17))
                        .foregroundColor(AppColors.cream)
                        .lineSpacing(5)

                    Text("You pray the words yourself. The app keeps your place, provides a meditation for each mystery, and deepens your focus with scripture and reflection.")
                        .font(AppFonts.bodyFont(15))
                        .foregroundColor(AppColors.cream.opacity(0.8))
                        .lineSpacing(5)

                    Divider()
                        .background(AppColors.gold.opacity(0.2))
                        .padding(.vertical, 4)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("The app provides:")
                            .font(AppFonts.headlineFont(14))
                            .foregroundColor(AppColors.gold)

                        AppFeatureRow(icon: "bookmark",     label: "Meditations for every mystery")
                        AppFeatureRow(icon: "text.quote",   label: "Scripture for each mystery — for study, not recited during prayer")
                        AppFeatureRow(icon: "calendar",     label: "Daily mystery auto-selected by traditional schedule")
                        AppFeatureRow(icon: "book",         label: "Multiple meditation styles — General, Saint, Situational, Contemplative")
                    }
                }
                .multilineTextAlignment(.leading)
            },
            bottomContent: {
                OnboardingNextButton(label: "Next") {
                    withAnimation(.easeInOut(duration: 0.3)) { currentPage = 1 }
                }
            }
        )
    }

    // MARK: - Slide 2: What the Process Is Like

    private var slide2: some View {
        OnboardingSlideLayout(
            icon: "figure.walk",
            iconIsGradient: false,
            title: "How a Session Works",
            content: {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Each time you open the app, a full Rosary session flows like this:")
                        .font(AppFonts.bodyFont(15))
                        .foregroundColor(AppColors.cream.opacity(0.8))
                        .lineSpacing(5)

                    VStack(spacing: 14) {
                        NumberedStepRow(number: "1", icon: "calendar",    title: "Today's mystery is chosen",  detail: "The traditional schedule assigns Joyful, Sorrowful, or Glorious by day. Luminous is available but not in the default rotation — you can always pick any set.")
                        NumberedStepRow(number: "2", icon: "sparkles",    title: "Choose how to meditate",     detail: "General, from a Saint, Situational, or Contemplative — each style brings a different lens to the same mysteries.")
                        NumberedStepRow(number: "3", icon: "book.closed", title: "Pray 5 decades",             detail: "The app guides you through each mystery at your own pace. You pray the prayers; the app holds your place.")
                        NumberedStepRow(number: "4", icon: "heart",       title: "Reflect and journal",        detail: "Close with a moment of reflection and an optional journal entry to capture what moved you.")
                    }
                }
                .multilineTextAlignment(.leading)
            },
            bottomContent: {
                OnboardingNextButton(label: "Next") {
                    withAnimation(.easeInOut(duration: 0.3)) { currentPage = 2 }
                }
            }
        )
    }

    // MARK: - Slide 3: Begin or Learn More

    private var slide3: some View {
        OnboardingSlideLayout(
            icon: "rays",
            iconIsGradient: false,
            title: "Begin Your Journey",
            content: {
                Text("Each prayer is a step closer to grace. Begin now, or take a moment to explore the different ways to pray the Rosary.")
                    .font(AppFonts.italicFont(16))
                    .foregroundColor(AppColors.cream.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
            },
            bottomContent: {
                VStack(spacing: 14) {
                    Button {
                        onComplete()
                    } label: {
                        Text("Begin Prayer")
                            .font(AppFonts.headlineFont(17))
                            .foregroundColor(AppColors.background)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [AppColors.gold, AppColors.goldLight],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(30)
                    }

                    Button {
                        showMethodsSheet = true
                    } label: {
                        HStack(spacing: 6) {
                            Text("Methods of Praying the Rosary")
                                .font(AppFonts.bodyFont(15))
                                .foregroundColor(AppColors.gold)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(AppColors.gold)
                        }
                        .padding(.vertical, 12)
                    }
                }
            }
        )
    }
}

// MARK: - OnboardingSlideLayout

/// Reusable full-screen slide: icon + title scroll area + fixed bottom buttons.
private struct OnboardingSlideLayout<Content: View, Bottom: View>: View {

    let icon: String
    let iconIsGradient: Bool
    let title: String
    @ViewBuilder let content: () -> Content
    @ViewBuilder let bottomContent: () -> Bottom

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    Group {
                        if iconIsGradient {
                            Image(systemName: icon)
                                .font(.system(size: 64, weight: .thin))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [AppColors.gold, AppColors.goldLight],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        } else {
                            Image(systemName: icon)
                                .font(.system(size: 64, weight: .thin))
                                .foregroundColor(AppColors.gold)
                        }
                    }
                    .padding(.top, 20)

                    Text(title)
                        .font(AppFonts.headlineFont(26))
                        .foregroundColor(AppColors.cream)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)

                    content()
                        .padding(.horizontal, 28)

                    Spacer(minLength: 20)
                }
            }

            // Fixed bottom — fades into gradient
            VStack {
                bottomContent()
                    .padding(.horizontal, 28)
                    .padding(.bottom, 44)
                    .padding(.top, 16)
            }
            .background(
                LinearGradient(
                    colors: [Color.clear, AppColors.background.opacity(0.95)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea(edges: .bottom)
            )
        }
    }
}

// MARK: - Supporting Components

private struct OnboardingNextButton: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(label)
                    .font(AppFonts.headlineFont(17))
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundColor(AppColors.background)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [AppColors.gold, AppColors.goldLight],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(30)
        }
    }
}

/// Slide 1 — compact icon + label row listing what the app provides.
private struct AppFeatureRow: View {
    let icon: String
    let label: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(AppColors.gold)
                .frame(width: 20)

            Text(label)
                .font(AppFonts.bodyFont(14))
                .foregroundColor(AppColors.cream.opacity(0.8))

            Spacer()
        }
    }
}

/// Slide 2 — numbered step with a title and detail line.
private struct NumberedStepRow: View {
    let number: String
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppColors.gold.opacity(0.15))
                    .frame(width: 38, height: 38)
                Text(number)
                    .font(AppFonts.headlineFont(16))
                    .foregroundColor(AppColors.gold)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(AppFonts.headlineFont(14))
                    .foregroundColor(AppColors.cream)

                Text(detail)
                    .font(AppFonts.bodyFont(13))
                    .foregroundColor(AppColors.textSecondary)
                    .lineSpacing(4)
            }

            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingView(onComplete: {})
}
