//
//  ChantLibraryPages.swift
//  Lumen Viae
//
//  The pages the library's home opens beyond a chant's own: the index of
//  the sung sets (`.chantSets`), and every chant under its
//  topic, or one topic, or the Mass of the Angels (`.chantBrowse`). Both
//  are pushed, with the gold Back in the bar.
//

import SwiftUI

// MARK: - ChantBrowseScope

/// What the browse page lists
enum ChantBrowseScope: Hashable {
    /// Every chant, under its topic
    case all
    /// One topic (`ChantGroup.id`)
    case group(String)
    /// The Ordinary of the Mass of the Angels, in the order it is sung
    case massOfTheAngels

    static let massSetting = "Mass of the Angels"

    var title: String {
        switch self {
        case .all: return "All Chants"
        case .group: return group?.title ?? "Chants"
        case .massOfTheAngels: return Self.massSetting
        }
    }

    /// The section a scope of one topic lists
    var group: ChantGroup? {
        guard case .group(let id) = self else { return nil }
        return ChantCatalog.groups.first { $0.id == id }
    }

    /// The chants in a scope of one list; nil for every topic
    var chants: [Chant]? {
        switch self {
        case .all:
            return nil
        case .group:
            return group.map { ChantCatalog.chants(in: $0) } ?? []
        case .massOfTheAngels:
            return ChantCatalog.all.filter { $0.groupID == "mass" && $0.setting == Self.massSetting }
        }
    }
}

// MARK: - ChantBrowsePage

struct ChantBrowsePage: View {

    @Environment(AppRouter.self) private var router
    let scope: ChantBrowseScope

    private var player = ChantPlayer.shared

    init(scope: ChantBrowseScope) {
        self.scope = scope
    }

    var body: some View {
        ZStack {
            AppColors.appGradient.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 34) {
                    Text(scope.title)
                        .font(AppFonts.titleFont(26))
                        .foregroundColor(AppColors.cream)
                        .accessibilityAddTraits(.isHeader)
                        .frame(maxWidth: .infinity)

                    if let chants = scope.chants {
                        if chants.count > 1 {
                            ChantSetPlayButton(
                                queue: ChantQueue.chants(chants, title: scope.title),
                                title: "Play all"
                            )
                        }
                        if let group = scope.group, group.parts.contains(where: { $0.title != nil }) {
                            parts(of: group)
                        } else {
                            list(chants)
                        }
                    } else {
                        ForEach(ChantCatalog.groups) { group in
                            VStack(alignment: .leading, spacing: 10) {
                                ChantSectionHeading(kicker: nil, title: group.title, note: group.note, titleSize: 19)
                                parts(of: group)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 48)
            }
            .topChromeFade()
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) { ChantBackButton() }
        }
    }

    /// A section's chants, each part under its subheading: the Masses of
    /// the Ordinary, the seasons
    private func parts(of group: ChantGroup) -> some View {
        VStack(alignment: .leading, spacing: 22) {
            ForEach(Array(group.parts.enumerated()), id: \.offset) { _, part in
                VStack(alignment: .leading, spacing: 8) {
                    if let title = part.title {
                        ChantPartHeading(title: title, note: part.note)
                            .padding(.top, 6)
                    }
                    list(ChantCatalog.chants(in: part))
                }
            }
        }
    }

    private func list(_ chants: [Chant]) -> some View {
        VStack(spacing: 0) {
            ChantRule()
            ForEach(chants) { chant in
                ChantLibraryRow(chant: chant, player: player) { router.push(ChantTap.route(to: chant)) }
            }
        }
    }
}

// MARK: - ChantSetsPage

/// The sung sets as an index: each occasion opens on its own page
/// (`ChantSetPage`), as a set of the reader's own does
struct ChantSetsPage: View {

    @Environment(AppRouter.self) private var router

    var body: some View {
        ZStack {
            AppColors.appGradient.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 26) {
                    VStack(spacing: 8) {
                        Text("Sung Sets")
                            .font(AppFonts.titleFont(26))
                            .foregroundColor(AppColors.cream)
                            .accessibilityAddTraits(.isHeader)
                        Text("Chants sung one after another, for a time of prayer.")
                            .font(AppFonts.readingItalicFont(16))
                            .foregroundColor(AppColors.cream.opacity(0.78))
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 28)

                    ChantOccasionsSection(
                        openSet: { router.push(.chantSet($0)) }
                    )
                }
                .padding(.top, 8)
                .padding(.bottom, 48)
            }
            .topChromeFade()
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) { ChantBackButton() }
        }
    }
}
