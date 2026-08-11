//
//  TrueDevotionReaderView.swift
//  Lumen Viae
//
//  Table of contents for reading the full text of True Devotion.
//  Shows overall progress, a continue-reading card that resumes the
//  exact spot, and every chapter grouped by part with its read state.
//
//  Reading state is owned by TrueDevotionReaderViewModel; this view and the
//  chapter reader below it only present it.
//

import SwiftUI
import SwiftData

struct TrueDevotionReaderView: View {

    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    /// Owned here and handed down explicitly, so every chapter pushed from
    /// this screen — including the next-chapter chain — shares one instance.
    @State private var viewModel = TrueDevotionReaderViewModel()

    let library: TrueDevotionLibrary

    init(library: TrueDevotionLibrary = .shared) {
        self.library = library
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            AppColors.appGradient
                .ignoresSafeArea()

            if let book = library.book {
                content(book)
            } else {
                Text("The book could not be loaded.")
                    .font(AppFonts.bodyFont(15))
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 6) {
                        AppIcon("ph-caret-left", size: 14)
                        Text("Back")
                            .font(AppFonts.bodyFont(16))
                    }
                    .foregroundColor(AppColors.gold)
                }
            }
        }
        .onAppear {
            viewModel.setModelContext(modelContext)
            viewModel.loadProgress()
        }
        .alert(
            "Something went wrong",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private func content(_ book: TrueDevotionBook) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                header(book)
                    .devotionalEntrance()

                if viewModel.hasStartedReading {
                    progressSummary(book)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                        .devotionalEntrance(delay: 0.08)
                }

                if let continueChapter = viewModel.continueChapter(in: book) {
                    continueCard(continueChapter)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 28)
                        .devotionalEntrance(delay: 0.12)
                }

                chapterList(book)
                    .padding(.horizontal, 20)

                sourceNote(book)
                    .padding(.horizontal, 32)
                    .padding(.top, 28)
                    .padding(.bottom, 40)
            }
        }
    }

    // MARK: - Header

    private func header(_ book: TrueDevotionBook) -> some View {
        VStack(spacing: 12) {
            AppIcon("ph-book-open", size: 36)
                .foregroundColor(AppColors.gold)
                .breathingGlow(AppColors.gold)
                .padding(.top, 24)

            Text(book.title)
                .font(AppFonts.headlineFont(26))
                .foregroundColor(AppColors.cream)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Text(book.author)
                .font(AppFonts.italicFont(16))
                .foregroundColor(AppColors.gold.opacity(0.8))

            OrnamentDivider()
                .padding(.horizontal, 40)
                .padding(.top, 8)
        }
        .padding(.bottom, 20)
    }

    // MARK: - Progress Summary

    private func progressSummary(_ book: TrueDevotionBook) -> some View {
        let completed = viewModel.completedCount(of: book)
        let total = book.chapters.count

        return VStack(spacing: 8) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(AppColors.cardBackground.opacity(0.8))

                    RoundedRectangle(cornerRadius: 3)
                        .fill(AppColors.gold)
                        .frame(width: geometry.size.width * viewModel.progressPercentage(of: book))
                }
            }
            .frame(height: 4)

            Text(completed == total
                 ? "You have read the whole book"
                 : "\(completed) of \(total) chapters read")
                .font(AppFonts.bodyFont(12))
                .foregroundColor(AppColors.textSecondary)
        }
    }

    // MARK: - Continue Card

    private func continueCard(_ chapter: TrueDevotionChapter) -> some View {
        NavigationLink {
            TrueDevotionChapterReaderView(
                chapterID: chapter.id,
                viewModel: viewModel,
                library: library
            )
        } label: {
            HStack(spacing: 14) {
                AppIcon("ph-book-open-fill", size: 22)
                    .foregroundColor(AppColors.background)

                VStack(alignment: .leading, spacing: 2) {
                    Text("CONTINUE READING")
                        .font(AppFonts.labelFont(10))
                        .tracking(2)
                        .foregroundColor(AppColors.background.opacity(0.7))

                    Text(chapter.title)
                        .font(AppFonts.headlineFont(16))
                        .foregroundColor(AppColors.background)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                }

                Spacer()

                AppIcon("ph-caret-right", size: 16)
                    .foregroundColor(AppColors.background.opacity(0.7))
            }
            .padding(16)
            .goldCTABackground()
        }
        .buttonStyle(SacredCardButtonStyle())
    }

    // MARK: - Chapter List

    private func chapterList(_ book: TrueDevotionBook) -> some View {
        VStack(spacing: 10) {
            ForEach(Array(book.chapters.enumerated()), id: \.element.id) { index, chapter in
                if let partTitle = partHeaderTitle(before: chapter, in: book) {
                    partHeader(partTitle)
                        .padding(.top, index == 0 ? 0 : 18)
                }

                chapterRow(chapter)
                    .devotionalEntrance(delay: 0.16 + Double(index) * 0.03)
            }
        }
    }

    /// Part header shown before the first chapter of each part
    private func partHeaderTitle(before chapter: TrueDevotionChapter, in book: TrueDevotionBook) -> String? {
        guard let index = book.chapterIndex(id: chapter.id) else { return nil }
        let isFirstOfPart = index == 0 || book.chapters[index - 1].part != chapter.part
        guard isFirstOfPart, chapter.part > 0 else { return nil }
        return book.parts.first { $0.number == chapter.part }?.title
    }

    private func partHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(AppFonts.labelFont(11))
            .tracking(2)
            .foregroundColor(AppColors.gold.opacity(0.8))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 6)
    }

    private func chapterRow(_ chapter: TrueDevotionChapter) -> some View {
        let isCompleted = viewModel.isCompleted(chapter.id)
        let isInProgress = viewModel.isInProgress(chapter.id)

        return NavigationLink {
            TrueDevotionChapterReaderView(
                chapterID: chapter.id,
                viewModel: viewModel,
                library: library
            )
        } label: {
            HStack(spacing: 14) {
                AppIcon(
                    isCompleted ? "ph-check-circle-fill" : (isInProgress ? "ph-book-open-fill" : "ph-circle"),
                    size: 20
                )
                .foregroundColor(isCompleted || isInProgress ? AppColors.gold : AppColors.textSecondary.opacity(0.5))

                VStack(alignment: .leading, spacing: 3) {
                    Text(chapter.title)
                        .font(AppFonts.headlineFont(15))
                        .foregroundColor(AppColors.cream)
                        .multilineTextAlignment(.leading)

                    Text("\(chapter.estimatedMinutes) min")
                        .font(AppFonts.bodyFont(12))
                        .foregroundColor(AppColors.textSecondary)
                }

                Spacer()

                AppIcon("ph-caret-right", size: 14)
                    .foregroundColor(AppColors.gold.opacity(0.6))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppColors.cardBackground.opacity(isCompleted ? 0.5 : 0.85))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(AppColors.gold.opacity(isInProgress ? 0.35 : 0.15), lineWidth: 1)
            )
        }
        .buttonStyle(SacredCardButtonStyle())
    }

    // MARK: - Source Note

    private func sourceNote(_ book: TrueDevotionBook) -> some View {
        VStack(spacing: 6) {
            OrnamentDivider(showsCross: false)
                .padding(.horizontal, 40)
                .padding(.bottom, 6)

            Text(book.translator)
                .font(AppFonts.bodyFont(12))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)

            Text(book.sourceNote)
                .font(AppFonts.bodyFont(11))
                .foregroundColor(AppColors.textSecondary.opacity(0.7))
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        TrueDevotionReaderView()
    }
    // The pushed chapter reader reads UserSettings from the environment,
    // so without this the preview traps as soon as a chapter is opened.
    .environment(UserSettings.shared)
    .modelContainer(for: [TrueDevotionReadingProgress.self])
}
