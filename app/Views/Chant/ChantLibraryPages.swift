//
//  ChantLibraryPages.swift
//  Lumen Viae
//
//  The pages the library's home opens beyond a chant's own: the sung sets
//  with their order of service (`.chantSets`), and every chant under its
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
        case .group(let id): return ChantCatalog.groups.first { $0.id == id }?.title ?? "Chants"
        case .massOfTheAngels: return Self.massSetting
        }
    }

    /// The chants in a scope of one list; nil for every topic
    var chants: [Chant]? {
        switch self {
        case .all:
            return nil
        case .group(let id):
            return ChantCatalog.groups.first { $0.id == id }.map { ChantCatalog.chants(in: $0) } ?? []
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
                        list(chants)
                    } else {
                        ForEach(ChantCatalog.groups) { group in
                            VStack(alignment: .leading, spacing: 10) {
                                ChantSectionHeading(kicker: nil, title: group.title, note: group.note, titleSize: 19)
                                list(ChantCatalog.chants(in: group))
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

    private func list(_ chants: [Chant]) -> some View {
        VStack(spacing: 0) {
            ChantRule()
            ForEach(chants) { chant in
                ChantLibraryRow(chant: chant, player: player) { router.push(.chant(id: chant.id)) }
            }
        }
    }
}

// MARK: - ChantSetsPage

/// The sung sets: an index of them over the chosen one's order of
/// service, sung in order, with PLAY ALL and the bookmark that keeps it
struct ChantSetsPage: View {

    @Environment(AppRouter.self) private var router
    @State private var openID: String?

    init(openID: String?) {
        _openID = State(initialValue: openID)
    }

    var body: some View {
        ZStack {
            AppColors.appGradient.ignoresSafeArea()

            ScrollViewReader { proxy in
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
                            openID: $openID,
                            open: { router.push(.chant(id: $0.id)) },
                            madeSet: { set in router.push(.chantSaved(.set(set.id))) },
                            reveal: { id in
                                withAnimation(Motion.crossfade) { proxy.scrollTo(id, anchor: .top) }
                            }
                        )
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 48)
                }
                .topChromeFade()
                .onAppear {
                    // Opened on a set from a tile or a card: its order of
                    // service, not the index above it, is what was asked for
                    guard openID != nil else { return }
                    DispatchQueue.main.async {
                        proxy.scrollTo(ChantOccasionsSection.orderAnchor, anchor: .top)
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) { ChantBackButton() }
        }
    }
}
