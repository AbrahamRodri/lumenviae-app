//
//  QuoteSection.swift
//  app
//
//  Created by Abraham Rodriguez on 2/10/26.
//

import SwiftUI

struct QuoteSection: View {
    let quote: String
    let author: String

    init(
        quote: String = "\"There is no problem, I tell you, no matter how difficult it is, that we cannot resolve by the prayer of the Holy Rosary.\"",
        author: String = "SISTER LUCIA OF FATIMA"
    ) {
        self.quote = quote
        self.author = author
    }

    var body: some View {
        VStack(spacing: 16) {
            // Ornamental rule in place of a plain icon
            OrnamentDivider()
                .frame(maxWidth: 210)

            // Quote text
            Text(quote)
                .font(AppFonts.readingItalicFont(18))
                .foregroundColor(AppColors.cream.opacity(0.92))
                .multilineTextAlignment(.center)
                .lineSpacing(7)

            // Attribution
            Text("— \(author)")
                .font(AppFonts.labelFont(10))
                .tracking(2.5)
                .foregroundColor(AppColors.gold)
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
        }
        .overlay(alignment: .bottomTrailing) {
            // Fine corner accent - bottom right (rotated)
            CornerAccent()
                .stroke(AppColors.gold.opacity(0.7), lineWidth: 1.5)
                .frame(width: 20, height: 20)
                .rotationEffect(.degrees(180))
                .padding(8)
        }
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
    QuoteSection()
        .padding()
        .background(AppColors.background)
}
