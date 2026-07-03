//
//  AppIcon.swift
//  Lumen Viae
//
//  Renders a vendored template icon from Assets.xcassets/Icons.
//
//  Icon sets:
//  - "ph-*"      Phosphor light weight (MIT) — general UI
//  - "ph-*-fill" Phosphor fill weight — selected/active states
//  - "ch-*"      Christicons (free commercial) — rosary, chalice,
//                monstrance, and other deeply Catholic glyphs
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
        Image(name)
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
    }
}

#Preview {
    HStack(spacing: 16) {
        AppIcon("ph-hands-praying", size: 24)
        AppIcon("ph-crown", size: 24)
        AppIcon("ch-rosary", size: 24)
        AppIcon("ch-chalice", size: 24)
        AppIcon("ph-flame-fill", size: 24)
    }
    .foregroundColor(AppColors.gold)
    .padding()
    .background(AppColors.background)
}
