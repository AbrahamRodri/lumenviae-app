//
//  ChantOccasionsSection.swift
//  Lumen Viae
//
//  The Occasions board: the sets of chants sung in order, for someone who
//  would follow along or lead a group — Benediction, a visit to the
//  Blessed Sacrament, a sung Rosary, before bed, before work, for the
//  dead — as a numbered index. Each opens on its own page
//  (`ChantSetPage`), where it is sung; beneath the index, a set of the
//  reader's own is begun.
//

import SwiftUI

struct ChantOccasionsSection: View {

    /// Opens a set's own page
    let openSet: (ChantSetSubject) -> Void

    @State private var namingSet = false

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            index
                .padding(.horizontal, 12)

            makeYourOwn
                .padding(.horizontal, 20)
        }
        .sheet(isPresented: $namingSet) {
            ChantNewSetSheet { set in openSet(.own(set.id)) }
                .presentationDetents([.medium])
                .dynamicTypeSize(...DynamicTypeSize.appMaximum)
        }
    }

    // MARK: - Index

    private var index: some View {
        VStack(spacing: 2) {
            ForEach(Array(ChantLibraryData.occasions.enumerated()), id: \.element.id) { number, occasion in
                indexRow(occasion, numeral: "\(number + 1)")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Occasions")
    }

    private func indexRow(_ occasion: ChantOccasion, numeral: String) -> some View {
        let chants = occasion.distinctChants().count
        return Button {
            openSet(.occasion(occasion.id))
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: 14) {
                Text(numeral)
                    .font(AppFonts.titleFont(13))
                    .foregroundColor(Rubric.text)
                    .frame(width: 26, alignment: .center)

                VStack(alignment: .leading, spacing: 3) {
                    Text(occasion.title)
                        .font(AppFonts.titleFont(16))
                        .foregroundColor(AppColors.cream)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(occasion.note)
                        .font(AppFonts.readingItalicFont(14))
                        .foregroundColor(AppColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 3) {
                    Text(Self.minutes(occasion.duration()).uppercased())
                        .font(AppFonts.labelFont(8.5))
                        .tracking(1)
                        .foregroundColor(AppColors.textSecondary)
                        .accessibilityLabel(Self.spokenMinutes(occasion.duration()))
                    Text(chants == 1 ? "1 chant" : "\(chants) chants")
                        .font(AppFonts.readingItalicFont(12.5))
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(SacredCardButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens the set")
    }

    // MARK: - Make your own

    private var makeYourOwn: some View {
        Button {
            namingSet = true
        } label: {
            HStack(spacing: 14) {
                AppIcon("ph-plus", size: 16)
                    .foregroundColor(AppColors.gold)
                    .frame(width: 40, height: 40)
                    .overlay(Circle().strokeBorder(AppColors.gold.opacity(0.5), lineWidth: AppLine.hairline))
                VStack(alignment: .leading, spacing: 3) {
                    Text("Make your own set")
                        .font(AppFonts.readingFont(17))
                        .foregroundColor(AppColors.cream)
                    Text("Choose chants for an hour of prayer in church, a prayer group or family prayer")
                        .font(AppFonts.readingItalicFont(14))
                        .foregroundColor(AppColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(AppColors.gold.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(SacredCardButtonStyle())
        .accessibilityElement(children: .combine)
    }

    // MARK: - Arithmetic

    static func minutes(_ duration: TimeInterval) -> String {
        "\(max(1, Int((duration / 60).rounded()))) min"
    }

    static func spokenMinutes(_ duration: TimeInterval) -> String {
        let whole = max(1, Int((duration / 60).rounded()))
        return whole == 1 ? "1 minute" : "\(whole) minutes"
    }
}
