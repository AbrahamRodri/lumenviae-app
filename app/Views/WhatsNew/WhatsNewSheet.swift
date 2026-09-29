//
//  WhatsNewSheet.swift
//  Lumen Viae
//
//  A version's notes, in the sheet grammar: the version as kicker over
//  the title, one ruled row for each thing added — its glyph, its name,
//  one plain line — and a caret, because each row is a door straight to
//  what it names. One gold act at the foot, to go on.
//
//  The door is taken by the presenter once the sheet has gone
//  (`onOpen`), so a page is never pushed under a sheet still leaving.
//

import SwiftUI

struct WhatsNewSheet: View {

    let release: WhatsNewRelease

    /// Called with the route of the row chosen; the presenter dismisses
    /// the sheet and pushes it once the sheet has left
    let onOpen: (AppRoute) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    SheetHeader(
                        kicker: "Lumen Viae \(release.version)",
                        title: "What's New",
                        lead: "Added since you last updated. Each opens where it lives in the app."
                    )

                    SheetRule()

                    ForEach(release.items) { item in
                        Button {
                            onOpen(item.route)
                        } label: {
                            SheetRow(
                                item.title,
                                detail: item.detail,
                                icon: item.icon,
                                accessory: .caret,
                                detailLineLimit: nil
                            )
                        }
                        .buttonStyle(SacredCardButtonStyle())
                        .accessibilityHint("Opens \(item.title)")
                    }
                }
                .padding(.bottom, 12)
            }
            .scrollBounceBehavior(.basedOnSize)

            GoldCTAButton(title: "Continue", trailingIcon: "ph-check") {
                dismiss()
            }
            .padding(.horizontal, SheetMetrics.gutter)
            .padding(.top, 12)
            .padding(.bottom, 16)
        }
        .sheetGround()
    }
}

#Preview {
    Color.black.sheet(isPresented: .constant(true)) {
        WhatsNewSheet(release: WhatsNewRelease.all[0], onOpen: { _ in })
    }
}
