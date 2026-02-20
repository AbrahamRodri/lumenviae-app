//
//  ConsecrationJournalView.swift
//  Lumen Viae
//
//  ═══════════════════════════════════════════════════════════════════════════
//  CONSECRATION JOURNAL VIEW - DAILY REFLECTION
//  ═══════════════════════════════════════════════════════════════════════════
//
//  Allows the user to write a reflection based on the day's prompt.
//  Completing the journal marks the day as complete.
//
//  ═══════════════════════════════════════════════════════════════════════════

import SwiftUI

// MARK: - ConsecrationJournalView

struct ConsecrationJournalView: View {

    // MARK: - Properties

    @Binding var path: NavigationPath
    @Environment(ConsecrationViewModel.self) private var viewModel
    @FocusState private var isTextEditorFocused: Bool

    let dayNumber: Int

    @State private var journalText: String = ""

    // MARK: - Computed Properties

    private var day: ConsecrationDay? {
        ConsecrationData.day(dayNumber)
    }

    private var phase: ConsecrationPhase? {
        day?.phase
    }

    private var isConsecrationDay: Bool {
        dayNumber == 34
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background - use app gradient
            AppColors.appGradient
                .ignoresSafeArea()
                .onTapGesture {
                    isTextEditorFocused = false
                }

            VStack(spacing: 0) {
                // Top Bar
                topBar
                    .padding(.top, 8)

                // Content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        Spacer()
                            .frame(height: 20)

                        // Prompt
                        journalPrompt

                        // Text Editor
                        journalEditor

                        Spacer()
                            .frame(height: 100)
                    }
                    .padding(.horizontal, 24)
                }

                // Complete Button
                completeButton
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .keyboard) {
                Button("Done") {
                    isTextEditorFocused = false
                }
            }
        }
        .onAppear {
            journalText = viewModel.journalText
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(alignment: .center) {
            // Back Button
            Button {
                path.removeLast()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColors.cream.opacity(0.7))
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(AppColors.cardBackground)
                    )
            }

            Spacer()

            // Label
            VStack(spacing: 4) {
                Text("DAY \(dayNumber)")
                    .font(AppFonts.bodyFont(10))
                    .tracking(2)
                    .foregroundColor(AppColors.textSecondary)

                HStack(spacing: 6) {
                    Image(systemName: "pencil.line")
                        .font(.system(size: 10))
                    Text("REFLECTION")
                        .font(AppFonts.bodyFont(10))
                        .tracking(1)
                }
                .foregroundColor(AppColors.gold)
            }

            Spacer()

            // Spacer for symmetry
            Color.clear
                .frame(width: 36, height: 36)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Prompt

    private var journalPrompt: some View {
        VStack(spacing: 12) {
            Text("Today's Reflection")
                .font(AppFonts.headlineFont(20))
                .foregroundColor(AppColors.cream)

            Text(day?.journalPrompt ?? "Reflect on today's prayers and meditation.")
                .font(AppFonts.italicFont(16))
                .foregroundColor(AppColors.cream.opacity(0.8))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppColors.gold.opacity(0.2), lineWidth: 1)
                )
        )
    }

    // MARK: - Editor

    private var journalEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your Thoughts")
                .font(AppFonts.bodyFont(12))
                .tracking(1)
                .foregroundColor(AppColors.textSecondary)

            TextEditor(text: $journalText)
                .font(AppFonts.bodyFont(16))
                .foregroundColor(AppColors.cream)
                .scrollContentBackground(.hidden)
                .focused($isTextEditorFocused)
                .frame(minHeight: 200)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppColors.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    isTextEditorFocused
                                        ? AppColors.gold
                                        : AppColors.gold.opacity(0.2),
                                    lineWidth: isTextEditorFocused ? 2 : 1
                                )
                        )
                )
                .animation(.easeInOut(duration: 0.2), value: isTextEditorFocused)
        }
    }

    // MARK: - Complete Button

    private var completeButton: some View {
        Button {
            viewModel.completeDay(journalEntry: journalText)

            // Navigate based on day
            if isConsecrationDay {
                path.append(ConsecrationRoute.completion)
            } else {
                // Return to root (day overview)
                path.removeLast(path.count)
            }
        } label: {
            HStack {
                Image(systemName: isConsecrationDay ? "sparkles" : "checkmark.circle.fill")

                Text(isConsecrationDay ? "Complete Consecration" : "Complete Day")
                    .font(AppFonts.headlineFont(16))
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
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ConsecrationJournalView(path: .constant(NavigationPath()), dayNumber: 1)
            .environment(ConsecrationViewModel())
    }
}
