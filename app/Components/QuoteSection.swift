//
//  QuoteSection.swift
//  Lumen Viae
//
//  The daily quotation card on the home screen: an ornament rule above the
//  words, the quote in reading italic, and the attribution in gold beneath,
//  framed by a pair of corner accents on the diagonal.
//

import SwiftUI

struct QuoteSection: View {

    let quote: String
    let author: String

    /// The work the line comes from, when it can be cited.
    let source: String?

    init(
        quote: String = RosaryQuotes.all[0].text,
        author: String = RosaryQuotes.all[0].author,
        source: String? = nil
    ) {
        self.quote = quote
        self.author = author
        self.source = source
    }

    var body: some View {
        VStack(spacing: 16) {
            // Ornamental rule in place of a plain icon
            OrnamentDivider()
                .frame(maxWidth: 210)

            Text(quote)
                .font(AppFonts.readingItalicFont(18))
                .foregroundColor(AppColors.cream.opacity(0.92))
                .multilineTextAlignment(.center)
                .lineSpacing(7)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 4) {
                Text("— \(author)")
                    .font(AppFonts.labelFont(10))
                    .tracking(2.5)
                    .foregroundColor(AppColors.gold)
                    .multilineTextAlignment(.center)

                if let source {
                    Text(source)
                        .font(AppFonts.italicFont(11))
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.top, 8)
        }
        .padding(.vertical, 36)
        .padding(.horizontal, 28)
        .frame(maxWidth: .infinity)
        .background(AppColors.quoteBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            // Gold border
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(AppColors.gold.opacity(0.4), lineWidth: 1)
        )
        .overlay(alignment: .topLeading) {
            // Fine corner accent - top left
            CornerAccent()
                .stroke(AppColors.gold.opacity(0.7), lineWidth: 1.5)
                .frame(width: 20, height: 20)
                .padding(8)
                .accessibilityHidden(true)
        }
        .overlay(alignment: .bottomTrailing) {
            // Fine corner accent - bottom right (rotated)
            CornerAccent()
                .stroke(AppColors.gold.opacity(0.7), lineWidth: 1.5)
                .frame(width: 20, height: 20)
                .rotationEffect(.degrees(180))
                .padding(8)
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(quote) — \(author)")
    }
}

// MARK: - Corner Accent Shape

/// A custom shape for the thick corner accents (L-shaped)
struct CornerAccent: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Horizontal line from top-left going right
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))

        // Vertical line from top-left going down
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))

        return path
    }
}

#Preview {
    VStack(spacing: 24) {
        QuoteSection(
            quote: RosaryQuotes.all[10].text,
            author: RosaryQuotes.all[10].author,
            source: RosaryQuotes.all[10].source
        )
        QuoteSection(
            quote: RosaryQuotes.all[9].text,
            author: RosaryQuotes.all[9].author
        )
    }
    .padding()
    .background(AppColors.background)
}
