//
//  RosaryMethodsView.swift
//  Lumen Viae
//
//  Presented as a sheet from the onboarding "Methods of Praying the Rosary" button.
//  Explains the different meditation styles available in the app.
//
//  The cards are the kinds the library actually carries — the labels the
//  picker filters by, in the wording `MeditationLabel.displayName` gives
//  them, so a rename in that map reaches this page too. It used to
//  describe a "Standard" kind no set has ever carried, "Intentional"
//  meditations that have not been written, and a bead-by-bead Scriptural
//  Rosary promised as coming soon: three things a new reader would have
//  gone looking for and not found.
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
            description: "A brief reflection on the mystery, and often a prayer to close it — the words of preachers and doctors of the Church, read in a minute and carried through the decade.\n\nSt. Alphonsus Liguori · Ven. Fulton J. Sheen · St. John Henry Newman · St. Thomas Aquinas"
        ),
        MeditationKind(
            label: "Contemplative",
            icon: "ch-candle",
            title: "Inside the scene",
            description: "Longer passages that set you within the mystery rather than beside it — what was seen, heard, and felt there. Read slowly; there is no need to reach the end of the page before the decade does.\n\nBl. Anne Catherine Emmerich · Ven. Mary of Agreda · St. Ignatius of Loyola · Fr. Frederick William Faber"
        ),
        MeditationKind(
            label: "Saints",
            icon: "ph-user",
            title: "In a saint's own voice",
            description: "Marks a set whose voice is a saint of the Church, so it stands beside the other kinds rather than apart from them.\n\nA set of St. Alphonsus's reflections carries this mark and Reflections both."
        ),
        MeditationKind(
            label: "Scriptural",
            icon: "ch-bible",
            title: "The Gospel first",
            description: "The passage itself, then a few lines of meditation on it.\n\nThis is the shape the Seven Sorrows take, where the Gospel carries the whole of the scene."
        )
    ]

    var body: some View {
        ZStack {
            AppColors.appGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("METHODS OF PRAYING")
                            .font(AppFonts.headlineFont(11))
                            .tracking(3)
                            .foregroundColor(AppColors.gold)

                        Text("The Rosary")
                            .font(AppFonts.headlineFont(24))
                            .foregroundColor(AppColors.cream)
                    }

                    Spacer()

                    Button {
                        dismiss()
                    } label: {
                        AppIcon("ph-x", size: 14)
                            .foregroundColor(AppColors.textSecondary)
                            .padding(10)
                            .background(AppColors.cardBackground)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 28)
                .padding(.bottom, 20)

                Divider()
                    .background(AppColors.gold.opacity(0.2))

                // Content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Intro
                        Text("The Rosary is always the same prayer: the same mysteries, in the same order, with the same Aves between them. What changes is the voice you keep beside you while you pray them.\n\nEvery set holds a meditation for each mystery — five of them, or seven for the Seven Sorrows.")
                            .font(AppFonts.bodyFont(15))
                            .foregroundColor(AppColors.textSecondary)
                            .lineSpacing(ReadingTypography.lineSpacing(for: 15))
                            .multilineTextAlignment(.leading)
                            .padding(.horizontal, 24)
                            .padding(.top, 24)
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
                        Text("Open a mystery and you arrive at its shelf, where every set waits under its own painting. The funnel filters them by these kinds, and anything you pin is held at the top for next time. Each meditation can be read, or heard where a set carries narration.")
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
        }
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
                        .font(.system(size: 10, weight: .semibold, design: .serif))
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
                .strokeBorder(AppColors.gold.opacity(0.15), lineWidth: 0.5)
        )
    }
}

// MARK: - Preview

#Preview {
    RosaryMethodsView()
}
