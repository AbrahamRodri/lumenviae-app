//
//  QuotedPassageText.swift
//  Lumen Viae
//
//  A passage kept from a book, set apart on the page as a quotation.
//  The opening mark alone is gilded — large, in the display face, hung
//  in the margin the way a pull quote's is — the words stand flush
//  beside it in the italic, and the citation closes the block in the
//  small italic under a dash. The reader's own words follow separately
//  and take the versal, because a versal is for what they wrote.
//
//  The passage used to go through `DropCapText` like any paragraph,
//  which hung a small quotation mark before a gilded letter: the
//  illumination fell one character too late, and read as a misprint.
//

import SwiftUI

struct QuotedPassageText: View {

    let passage: String

    /// "St. Louis de Montfort, True Devotion…, Chapter I"; nil where the
    /// card has no room for it
    var citation: String?

    /// The reading size the passage is set at
    var size: CGFloat = 17

    var textColor: Color = AppColors.cream.opacity(0.92)

    /// Lines of the passage a card may show; nil on the page
    var lineLimit: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: (size * 0.55).rounded()) {
            Text(passage)
                .font(AppFonts.readingItalicFont(size))
                .foregroundColor(textColor)
                .lineSpacing(ReadingTypography.lineSpacing(for: size) - 2)
                .lineLimit(lineLimit)
                .fixedSize(horizontal: false, vertical: true)
                // The same mark, at the same measure, that `DropCapText`
                // hangs before a paragraph opening on a saying
                .gildedQuotationMark(bodySize: size)

            if let citation, !citation.isEmpty {
                Text("\u{2014} \(citation)")
                    .font(AppFonts.italicFont(max(12, (size - 3.5).rounded())))
                    .foregroundColor(AppColors.gold.opacity(0.78))
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.leading, GildedQuotationMark.margin(bodySize: size))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spoken)
    }

    private var spoken: String {
        var parts = ["Quotation: \(passage)"]
        if let citation, !citation.isEmpty { parts.append(citation) }
        return parts.joined(separator: ". ")
    }
}

// MARK: - Preview

#Preview {
    VStack(alignment: .leading, spacing: 30) {
        QuotedPassageText(
            passage: "It is through the most holy Virgin Mary that Jesus Christ came into the world, and it is also through her that He has to reign in the world.",
            citation: "St. Louis de Montfort, True Devotion to the Blessed Virgin Mary, Introduction (trans. Faber)",
            size: 17
        )
        QuotedPassageText(
            passage: "Love is swift, sincere, pious, pleasant, gentle, strong, patient, faithful, prudent, long-suffering, manly, and never seeking itself.",
            size: 15,
            textColor: AppColors.cream.opacity(0.85),
            lineLimit: 3
        )
    }
    .padding(24)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(AppColors.background)
}
