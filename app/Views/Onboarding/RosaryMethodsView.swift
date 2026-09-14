//
//  RosaryMethodsView.swift
//  Lumen Viae
//
//  Presented as a sheet from onboarding's "Kinds of Meditation" link.
//  Explains the kinds of meditation set the library carries.
//
//  The cards are the kinds the library actually carries — the labels the
//  picker filters by, in the wording `MeditationLabel.displayName` gives
//  them, so a rename in that map reaches this page too. It used to
//  describe a "Standard" kind no set has ever carried, "Intentional"
//  meditations that have not been written, and a bead-by-bead Scriptural
//  Rosary promised as coming soon: three things a new reader would have
//  gone looking for and not found.
//
//  It was titled "Methods of Praying the Rosary", which it is not: the
//  Rosary is prayed one way, and these are the words kept beside it.
//

import SwiftUI

// MARK: - RosaryMethodsView

struct RosaryMethodsView: View {

    @Environment(\.dismiss) private var dismiss

    // MARK: - The Kinds

    /// One kind of meditation: the API's own label, what praying with it
    /// is like, and a few of the voices that carry it.
    ///
    /// The voices are examples rather than an index — the library grows
    /// on the server, and this page must read honestly offline on a
    /// first launch, so it names what has been there rather than
    /// counting what is there this morning.
    private struct MeditationKind: Identifiable {
        let label: String
        let icon: String
        let title: String
        let description: String

        var id: String { label }
    }

    private let kinds: [MeditationKind] = [
        MeditationKind(
            label: "Considerations",
            icon: "ch-rosary",
            title: "A reading and a prayer",
            description: "A short reflection on the mystery, often with a prayer at the end. The words come from preachers and Doctors of the Church. Read it once, then keep it in mind through the decade.\n\nSt. Alphonsus Liguori · Ven. Fulton J. Sheen · St. John Henry Newman · St. Thomas Aquinas"
        ),
        MeditationKind(
            label: "Contemplative",
            icon: "ch-candle",
            title: "Inside the scene",
            description: "Longer passages that place you within the mystery: what was seen, heard, and felt there. Read slowly. You do not need to finish the page before the decade ends.\n\nBl. Anne Catherine Emmerich · Ven. Mary of Agreda · St. Ignatius of Loyola · Fr. Frederick William Faber"
        ),
        MeditationKind(
            label: "Saints",
            icon: "ph-user",
            title: "In a saint's own words",
            description: "A set written by a saint of the Church carries this label as well as its own kind.\n\nA set of St. Alphonsus's reflections, for example, is marked both Saints and Reflections."
        ),
        MeditationKind(
            label: "Scriptural",
            icon: "ch-bible",
            title: "The Gospel first",
            description: "The Scripture passage for the mystery, then a few lines of meditation on it.\n\nThe Seven Sorrows are set this way, because the Gospel tells the whole scene. For a verse on every bead, open the Scriptural Rosary from Explore."
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            SheetHeader(kicker: "Meditation sets", title: "Kinds of Meditation") {
                SheetHeaderAction(title: "Close") { dismiss() }
            }

            // Content
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Intro
                    Text("The Rosary is always the same prayer: the same mysteries in the same order, with ten Hail Marys for each. A meditation set gives you words to think about while you pray.\n\nEach set has one meditation for each mystery: five for the Rosary, or seven for the Seven Sorrows.")
                        .font(AppFonts.bodyFont(15))
                        .foregroundColor(AppColors.textSecondary)
                        .lineSpacing(ReadingTypography.lineSpacing(for: 15))
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal, 24)
                        // The header keeps its own room beneath it
                        .padding(.top, 8)
                        .padding(.bottom, 28)

                    // Method cards
                    VStack(spacing: 16) {
                        ForEach(kinds) { kind in
                            MethodDetailCard(
                                icon: kind.icon,
                                tag: MeditationLabel.displayName(kind.label),
                                title: kind.title,
                                description: kind.description
                            )
                        }
                    }
                    .padding(.horizontal, 20)

                    // Where the kinds are actually met
                    Text("Open a mystery to see its meditation sets, each under its own painting. The filter button sorts them by these kinds, and a set you pin stays at the top. You can read each meditation, or listen when a set has narration.")
                        .font(AppFonts.bodyFont(15))
                        .foregroundColor(AppColors.textSecondary)
                        .lineSpacing(ReadingTypography.lineSpacing(for: 15))
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal, 24)
                        .padding(.top, 28)
                        .padding(.bottom, 40)
                }
            }
        }
        .sheetGround()
    }
}

// MARK: - MethodDetailCard

private struct MethodDetailCard: View {
    let icon: String
    let tag: String
    let title: String
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Icon + tag row
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(AppColors.gold.opacity(0.12))
                        .frame(width: 44, height: 44)
                    AppIcon(icon, size: 19)
                        .foregroundColor(AppColors.gold)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(tag.uppercased())
                        .font(AppFonts.labelFont(10))
                        .tracking(2)
                        .foregroundColor(AppColors.gold.opacity(0.7))

                    Text(title)
                        .font(AppFonts.headlineFont(16))
                        .foregroundColor(AppColors.cream)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            // Description — paragraph-aware, so the voices that carry a
            // kind sit apart from the account of what it is
            ReadingText(
                text: description,
                size: 15,
                style: .body,
                textColor: AppColors.textSecondary
            )
        }
        .padding(18)
        .background(AppColors.cardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(AppColors.gold.opacity(0.15), lineWidth: AppLine.hairline)
        )
    }
}

// MARK: - Preview

#Preview {
    RosaryMethodsView()
}
