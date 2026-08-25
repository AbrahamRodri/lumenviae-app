//
//  BookCover.swift
//  Lumen Viae
//
//  A cloth-bound cover for the Spiritual Reading shelf: each book in its
//  own binding colour under gilt rules and a double hairline frame, the
//  title set small in Cinzel, the author at the foot — so the shelf
//  reads as a case of real books, each recognizable at a glance, rather
//  than four identical cards. A gold marker ribbon hangs over the top
//  edge of any book with a reading under way, the same ribbon language
//  as the home screen's standing volumes.
//
//  The binding colours are display, not catalog data — they live here
//  with the cover that wears them.
//

import SwiftUI

// MARK: - Binding colours

extension LibraryBookInfo {

    /// The book's cloth: muted and dark enough to sit on the page
    /// ground, distinct enough to name the book from across the room.
    var bindingColor: Color {
        switch id {
        case "imitation-of-christ":       return Color(hex: "44301e")  // old leather
        case "story-of-a-soul":           return Color(hex: "5e3140")  // rose-brown
        case "confessions-of-st-augustine": return Color(hex: "3d3a24") // bronze-olive
        case "dolorous-passion":          return Color(hex: "342a52")  // passion violet
        case "true-devotion":             return Color(hex: "2e3d66")  // Marian blue
        default:                          return Color(hex: "252542")
        }
    }
}

// MARK: - BookCover

struct BookCover: View {

    let info: LibraryBookInfo

    /// Whether a reading is under way — the marker ribbon shows over
    /// the top edge.
    var hasRibbon: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            gilt
                .padding(.top, 12)

            Spacer(minLength: 8)

            VStack(spacing: 10) {
                Text(info.title.uppercased())
                    .font(AppFonts.headlineFont(15))
                    .foregroundColor(AppColors.goldLight.opacity(0.95))
                    .tracking(1)
                    .multilineTextAlignment(.center)
                    .lineLimit(4)
                    .minimumScaleFactor(0.7)
                    .padding(.horizontal, 18)

                diamond
            }

            Spacer(minLength: 8)

            Text(info.author.uppercased())
                .font(AppFonts.labelFont(8))
                // Modest tracking: on a narrow cover the letterspacing
                // is what pushes a saint's name into an ellipsis
                .tracking(1.1)
                .foregroundColor(AppColors.gold.opacity(0.7))
                .lineLimit(1)
                .minimumScaleFactor(0.55)
                .padding(.horizontal, 10)

            gilt
                .padding(.top, 10)
                .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(0.70, contentMode: .fit)
        .background(cloth)
        .overlay(
            // The double hairline frame of a tooled binding
            RoundedRectangle(cornerRadius: 3)
                .strokeBorder(AppColors.gold.opacity(0.35), lineWidth: 0.6)
                .padding(6)
        )
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(AppColors.gold.opacity(0.25), lineWidth: 0.5)
        )
        .overlay(alignment: .topTrailing) {
            if hasRibbon {
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(AppColors.goldLight)
                    .frame(width: 9, height: 24)
                    .padding(.trailing, 18)
                    .offset(y: -6)
                    .shadow(color: .black.opacity(0.4), radius: 2, y: 1)
                    .accessibilityHidden(true)
            }
        }
        .shadow(color: .black.opacity(0.35), radius: 7, y: 5)
    }

    /// The cloth itself: the binding colour lit from the upper left,
    /// falling toward the fore-edge — the same rounding the home
    /// screen's spines carry.
    private var cloth: some View {
        ZStack {
            LinearGradient(
                colors: [
                    info.bindingColor.lightened(by: 0.10),
                    info.bindingColor,
                    info.bindingColor.darkened(by: 0.18)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // The hinge shadow along the spine edge
            LinearGradient(
                colors: [.black.opacity(0.25), .clear],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(maxWidth: 14)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// The pair of gilt rules at head and tail
    private var gilt: some View {
        VStack(spacing: 3) {
            Rectangle()
                .fill(AppColors.gold.opacity(0.55))
                .frame(height: 1)
            Rectangle()
                .fill(AppColors.gold.opacity(0.55))
                .frame(height: 1)
        }
        .padding(.horizontal, 14)
    }

    private var diamond: some View {
        Rectangle()
            .fill(AppColors.gold.opacity(0.75))
            .frame(width: 5, height: 5)
            .rotationEffect(.degrees(45))
            .accessibilityHidden(true)
    }
}

// MARK: - Shade helpers

private extension Color {

    /// A slightly lighter or darker cast of the same cloth, mixed in
    /// sRGB against white or black.
    func lightened(by amount: Double) -> Color {
        mixed(with: .white, fraction: amount)
    }

    func darkened(by amount: Double) -> Color {
        mixed(with: .black, fraction: amount)
    }

    func mixed(with other: Color, fraction: Double) -> Color {
        let a = UIColor(self)
        let b = UIColor(other)
        var (r1, g1, b1, o1): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
        var (r2, g2, b2, o2): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
        a.getRed(&r1, green: &g1, blue: &b1, alpha: &o1)
        b.getRed(&r2, green: &g2, blue: &b2, alpha: &o2)
        let f = CGFloat(fraction)
        return Color(
            red: Double(r1 + (r2 - r1) * f),
            green: Double(g1 + (g2 - g1) * f),
            blue: Double(b1 + (b2 - b1) * f),
            opacity: Double(o1 + (o2 - o1) * f)
        )
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        AppColors.appGradient.ignoresSafeArea()

        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)],
            spacing: 20
        ) {
            ForEach(LibraryCatalog.books) { book in
                BookCover(info: book, hasRibbon: book.id == "story-of-a-soul")
            }
        }
        .padding(24)
    }
}
