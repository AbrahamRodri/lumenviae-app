//
//  PrayerCompletionView.swift
//  app
//
//  Created by Abraham Rodriguez on 2/11/26.
//
//  Displayed after completing all 5 mysteries of the Rosary.
//  Offers option to record a journal entry or return home.

import SwiftUI

struct PrayerCompletionView: View {
    // Quote data (will come from API in future)
    let quoteText: String
    let quoteAuthor: String
    let backgroundImageURL: String?

    // Actions
    var onRecordDevotion: () -> Void = {}
    var onReturnHome: () -> Void = {}
    var onClose: () -> Void = {}

    var body: some View {
        ZStack {
            // Full-screen background image
            CompletionBackgroundImage(imageURL: backgroundImageURL)

            // Content overlay
            VStack(spacing: 0) {
                // Header
                CompletionHeader(onClose: onClose)

                Spacer()

                // Completion badge and title
                CompletionBadge()
                    .padding(.bottom, 24)

                // Quote card
                CompletionQuoteCard(
                    quote: quoteText,
                    author: quoteAuthor
                )
                .padding(.horizontal, 20)

                Spacer()

                // Action buttons
                VStack(spacing: 12) {
                    // Record Devotion (Journal) - Primary
                    Button(action: onRecordDevotion) {
                        HStack(spacing: 12) {
                            Image(systemName: "pencil.line")
                                .font(.system(size: 18))

                            Text("RECORD DEVOTION")
                                .font(AppFonts.bodyFont(16))
                                .tracking(2)
                        }
                        .foregroundColor(AppColors.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(AppColors.goldLight)
                        .cornerRadius(30)
                    }

                    // Return Home - Secondary
                    Button(action: onReturnHome) {
                        Text("RETURN HOME")
                            .font(AppFonts.bodyFont(16))
                            .tracking(2)
                            .foregroundColor(AppColors.cream)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                RoundedRectangle(cornerRadius: 30)
                                    .strokeBorder(AppColors.gold.opacity(0.5), lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
        }
    }
}

// MARK: - Background Image
struct CompletionBackgroundImage: View {
    let imageURL: String?

    var body: some View {
        ZStack {
            // Fallback gradient
            LinearGradient(
                colors: [
                    Color(hex: "3d3522"),
                    AppColors.background
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Remote image if available
            if let urlString = imageURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    default:
                        EmptyView()
                    }
                }
            }

            // Gradient overlay for text readability
            LinearGradient(
                colors: [
                    Color.clear,
                    AppColors.background.opacity(0.6),
                    AppColors.background.opacity(0.95)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
    }
}

// MARK: - Header
struct CompletionHeader: View {
    var onClose: () -> Void = {}

    var body: some View {
        HStack {
            Text("LUMEN VIAE")
                .font(AppFonts.bodyFont(12))
                .tracking(4)
                .foregroundColor(AppColors.cream.opacity(0.8))

            Spacer()

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColors.gold)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }
}

// MARK: - Completion Badge
struct CompletionBadge: View {
    var body: some View {
        VStack(spacing: 16) {
            // Checkmark circle
            ZStack {
                Circle()
                    .strokeBorder(AppColors.gold.opacity(0.6), lineWidth: 1)
                    .frame(width: 56, height: 56)

                Image(systemName: "checkmark")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(AppColors.gold)
            }

            // Title
            VStack(spacing: 4) {
                Text("THE ROSARY")
                    .font(AppFonts.headlineFont(28))
                    .foregroundColor(AppColors.gold)

                Text("IS COMPLETED")
                    .font(AppFonts.headlineFont(28))
                    .foregroundColor(AppColors.gold)
            }
        }
    }
}

// MARK: - Quote Card
struct CompletionQuoteCard: View {
    let quote: String
    let author: String

    var body: some View {
        VStack(spacing: 16) {
            // Opening quote mark
            Text("\u{201C}")
                .font(.system(size: 48, weight: .light, design: .serif))
                .foregroundColor(AppColors.gold.opacity(0.5))
                .offset(y: 10)

            // Quote text
            Text(quote)
                .font(AppFonts.italicFont(18))
                .foregroundColor(AppColors.cream)
                .multilineTextAlignment(.center)
                .lineSpacing(6)

            // Author with decorative lines
            HStack(spacing: 12) {
                Rectangle()
                    .fill(AppColors.gold.opacity(0.5))
                    .frame(width: 24, height: 1)

                Text(author.uppercased())
                    .font(AppFonts.bodyFont(12))
                    .tracking(2)
                    .foregroundColor(AppColors.gold)

                Rectangle()
                    .fill(AppColors.gold.opacity(0.5))
                    .frame(width: 24, height: 1)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 28)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppColors.background.opacity(0.85))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(AppColors.gold.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Preview
#Preview {
    PrayerCompletionView(
        quoteText: "The Rosary is the most beautiful and the most rich in graces of all prayers; it is the prayer that touches most the Heart of the Mother of God.",
        quoteAuthor: "St. Pius X",
        backgroundImageURL: nil
    )
}

