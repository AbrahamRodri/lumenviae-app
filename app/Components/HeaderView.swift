//
//  HeaderView.swift
//  app
//
//  Created by Abraham Rodriguez on 2/10/26.
//
//  Home header: the wordmark, framed by the app's own chrome. The faders
//  (Settings) and the colophon (About) sit together on the left; the
//  glass that opens Explore stands alone on the right. The two doors on
//  the left used to ride in the Chapel's day strip, which is a
//  reading of the liturgical day and had no business also being the only
//  door to the app's settings — a page-level strip carrying app-level
//  chrome, findable only by whoever thought to look there.
//
//  The streak flame is not here: it lives in the Chapel, on the page the
//  user arranges.
//

import SwiftUI

struct HeaderView: View {
    /// Opens Explore. A small glass in the corner, not a bar — the
    /// header stays the wordmark's.
    var onSearchTap: (() -> Void)?

    /// Opens Settings.
    var onSettingsTap: (() -> Void)?

    /// Opens About — the app's colophon.
    var onAboutTap: (() -> Void)?

    var body: some View {
        ZStack {
            VStack(spacing: 2) {
                Text(Constants.appName)
                    .font(AppFonts.titleFont(22))
                    .tracking(4)
                    .foregroundColor(AppColors.gold)

                Text(Constants.appTagline)
                    .font(AppFonts.bodyFont(10))
                    .tracking(2)
                    .foregroundColor(AppColors.textSecondary)
            }
            .frame(maxWidth: .infinity)

            // Settings and About keep the left, together, as the two
            // doors to the app's own pages; the glass stands alone on
            // the right, under the thumb, as the page's one act. Two
            // and one, so the wordmark stays framed rather than crowded
            // into a corner by three glyphs.
            HStack(spacing: 0) {
                if let onSettingsTap {
                    glyph("ph-faders", "Settings", action: onSettingsTap)
                }

                if let onAboutTap {
                    glyph("ph-info", "About Lumen Viae", action: onAboutTap)
                }

                Spacer(minLength: 0)

                if let onSearchTap {
                    glyph("ph-magnifying-glass", "Search", action: onSearchTap)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
    }

    private func glyph(
        _ icon: String,
        _ label: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            AppIcon(icon, size: 18)
                .foregroundColor(AppColors.gold.opacity(0.8))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(QuietGlyphButtonStyle())
        .accessibilityLabel(label)
    }
}

#Preview {
    HeaderView()
        .background(AppColors.background)
}
