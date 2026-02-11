//
//  QuoteSection.swift
//  app
//
//  Created by Abraham Rodriguez on 2/10/26.
//

import SwiftUI

struct QuoteSection: View {
    let quote: String
    let attribution: String

    init(
        quote: String = "\"There is no problem, I tell you, no matter how difficult it is, that we cannot resolve by the prayer of the Holy Rosary.\"",
        attribution: String = "SISTER LUCIA OF FATIMA"
    ) {
        self.quote = quote
        self.attribution = attribution
    }

    var body: some View {
        VStack(spacing: 16) {
            // Decorative icon
            Image(systemName: "sparkles")
                .font(.system(size: 24))
                .foregroundColor(AppColors.gold)

            // Quote text
            Text(quote)
                .font(AppFonts.italicFont(16))
                .foregroundColor(AppColors.cream.opacity(0.9))
                .multilineTextAlignment(.center)
                .lineSpacing(6)

            // Attribution
            Text("— \(attribution)")
                .font(AppFonts.bodyFont(11))
                .tracking(2)
                .foregroundColor(AppColors.gold)
                .padding(.top, 8)
        }
        .padding(.vertical, 32)
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.quoteBackground)
        )
    }
}

#Preview {
    QuoteSection()
        .padding()
        .background(AppColors.background)
}
