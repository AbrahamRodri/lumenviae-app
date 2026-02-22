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
            // Decorative stars icon
            Image(systemName: "sparkles")
                .font(.system(size: 24))
                .foregroundColor(AppColors.gold)

            // Quote text
            Text(quote)
                .font(AppFonts.italicFont(18))
                .foregroundColor(AppColors.cream.opacity(0.9))
                .multilineTextAlignment(.center)
                .lineSpacing(6)

            // Attribution
            Text("— \(author)")
                .font(AppFonts.bodyFont(11))
                .tracking(2)
                .foregroundColor(AppColors.gold)
                .padding(.top, 8)
        }
        .padding(.vertical, 40)
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
            // Thick corner accent - top left
            CornerAccent()
                .stroke(AppColors.gold.opacity(0.8), lineWidth: 3)
                .frame(width: 24, height: 24)
                .padding(6)
        }
        .overlay(alignment: .bottomTrailing) {
            // Thick corner accent - bottom right (rotated)
            CornerAccent()
                .stroke(AppColors.gold.opacity(0.8), lineWidth: 3)
                .frame(width: 24, height: 24)
                .rotationEffect(.degrees(180))
                .padding(6)
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
