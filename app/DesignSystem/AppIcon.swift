//
//  AppIcon.swift
//  Lumen Viae
//
//  Renders a vendored template icon from Assets.xcassets/Icons.
//
//  Icon sets:
//  - "ph-*"      Phosphor light weight (MIT) — general UI
//  - "ph-*-fill" Phosphor fill weight — selected/active states
//  - "ch-*"      Christicons (free commercial) — chalice, monstrance,
//                keys, dove and other deeply Catholic glyphs
//  - "lv-*"      Drawn for this app where neither family read correctly,
//                on a 24 viewBox at 1.5, the weight of the ch-* glyphs
//                they stand beside: the rosary, the hours' rooster, bell
//                and lamp, the mysteries' marks. Tools/IconAudit/draw.py
//                writes them; edit there, never the SVG.
//
//  All assets are template-rendered, so tint with .foregroundColor
//  or .foregroundStyle exactly like an SF Symbol.
//

import SwiftUI

struct AppIcon: View {

    let name: String
    var size: CGFloat = 20

    init(_ name: String, size: CGFloat = 20) {
        self.name = name
        self.size = size
    }

    var body: some View {
        // Decorative on purpose: without this SwiftUI derives a label
        // from the asset name and VoiceOver announces "ph book open".
        // Every glyph in the app either sits inside a control that
        // carries its own label, or beside the text it decorates.
        Image(decorative: name)
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
    }
}

#Preview {
    HStack(spacing: 16) {
        AppIcon("ch-praying-hands", size: 24)
        AppIcon("ph-crown", size: 24)
        AppIcon("lv-rosary", size: 24)
        AppIcon("ch-chalice", size: 24)
        AppIcon("ph-flame-fill", size: 24)
    }
    .foregroundColor(AppColors.gold)
    .padding()
    .background(AppColors.background)
}
