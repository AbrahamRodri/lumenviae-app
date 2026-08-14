//
//  QuoteSection.swift
//  Lumen Viae
//
//  The daily quotation on the home screen, set as a colophon rather than a
//  card: an ornament rule above the words, the quote in reading italic, the
//  attribution in gold, and a closing rule beneath. No box — a filled panel
//  with a gold border and corner ticks read as a slab pasted onto the page,
//  and the page itself is the frame.
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
        VStack(spacing: 18) {
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
            .padding(.top, 2)

            // Closes the passage the way the rule above opened it, with
            // no cross — the pair reads as ruling, not as a second altar
            OrnamentDivider(showsCross: false, lineOpacity: 0.3)
                .frame(maxWidth: 120)
                .padding(.top, 4)
        }
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(quote) — \(author)")
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
