//
//  SpanishBetaNotice.swift
//  app
//
//  Spanish is a beta, and its words were translated with AI. Abraham,
//  14 Nov 2026: "for the spanish i want a warning that stays on the app
//  at the top that highlights that spanish is beta and ai translated they
//  can click out of it but it will come back daily to keep warning them.
//  also a more in depth warning should come for a spanish users first
//  time", then "Yes" to version 2 (reports/design/spanish-beta/).
//
//  Two parts, both in Spanish only:
//  - a strip at the top of every tab, under the clock and above the
//    page's own head: closed with its X, it comes back the next calendar
//    day; a tap opens the sheet. Never over a prayer, which is pushed
//    over the tab and leaves the strip behind.
//  - a sheet the first time the app opens in Spanish, which says the
//    old one-time notice's words (`AppLanguage.noticeWithBeta`) word for
//    word, then what was checked, a way to report a mistake and a way to
//    use the app in English. Someone who saw the old notice sees it once.
//

import SwiftUI
import UIKit

enum SpanishBeta {

    /// The day the strip was last closed, as yyyy-MM-dd in the phone's
    /// calendar
    static let closedOnKey = "spanishBeta.stripClosedOn"
    /// The sheet has been seen and its Got It pressed
    static let sheetSeenKey = "spanishBeta.sheetSeen"

    static func dayStamp(_ date: Date, calendar: Calendar = .current) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }

    /// The strip stands in Spanish unless it was closed today
    static func showsStrip(
        closedOn: String, now: Date = Date(), calendar: Calendar = .current, inSpanish: Bool = AppLanguage.isSpanish
    ) -> Bool {
        inSpanish && closedOn != dayStamp(now, calendar: calendar)
    }

    /// Owed the first time the app opens in Spanish, the old notice's
    /// readers included, until its Got It is pressed
    static func owesSheet(defaults: UserDefaults = .standard, inSpanish: Bool = AppLanguage.isSpanish) -> Bool {
        inSpanish && !defaults.bool(forKey: sheetSeenKey)
    }

    static func markSheetSeen(defaults: UserDefaults = .standard) {
        defaults.set(true, forKey: sheetSeenKey)
        // The old one-time notice is answered too
        AppLanguage.markTranslationNoticeShown(defaults: defaults)
    }

    /// A mistake reported by mail: subject "Error en español", the
    /// version and the phone beneath a rule
    static var reportURL: URL? {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = Constants.supportEmail
        let body = [
            "", "", "—",
            "Lumen Viae \(Bundle.main.appVersion) (\(Bundle.main.buildNumber))",
            "\(FeedbackDraft.deviceModel) · iOS \(UIDevice.current.systemVersion)",
        ].joined(separator: "\n")
        components.queryItems = [
            URLQueryItem(name: "subject", value: "Error en español"),
            URLQueryItem(name: "body", value: body),
        ]
        return components.url
    }
}

// MARK: - The strip

/// The strip at the top of a tab: ES · BETA, the line, a caret, and the X
struct SpanishBetaStrip: View {
    let onOpen: () -> Void
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onOpen) {
                HStack(spacing: 10) {
                    Text(verbatim: "ES · BETA")
                        .font(AppFonts.labelFont(10))
                        .tracking(1.4)
                        .foregroundColor(AppColors.gold)
                        .fixedSize()
                    HStack(spacing: 4) {
                        Text(
                            "Translated with AI. It may have mistakes.",
                            comment:
                                "Spanish beta strip at the top of every tab, shown only in Spanish: the app's words were translated with AI and may have mistakes. Approved wording."
                        )
                        .font(AppFonts.bodyFont(14.5))
                        .foregroundColor(AppColors.cream.opacity(0.92))
                        .lineLimit(1)
                        // Whole on a 375 pt phone: the line a little
                        // smaller rather than cut
                        .minimumScaleFactor(0.8)
                        AppIcon("ph-caret-right", size: 10)
                            .foregroundColor(AppColors.gold)
                    }
                    Spacer(minLength: 0)
                }
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(QuietGlyphButtonStyle())
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(
                Text(
                    "Spanish, beta. Translated with artificial intelligence. It may have mistakes.",
                    comment: "VoiceOver, the Spanish beta strip: what it says, read in full. Approved wording.")
            )
            .accessibilityHint(
                Text(
                    "Opens the notice about Spanish",
                    comment: "VoiceOver hint, the Spanish beta strip: a tap opens the fuller notice")
            )
            .accessibilityAddTraits(.isButton)

            Button(action: onClose) {
                AppIcon("ph-x", size: 13)
                    .foregroundColor(AppColors.textSecondary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(QuietGlyphButtonStyle())
            .accessibilityLabel(
                Text(
                    "Close the notice",
                    comment: "VoiceOver, the Spanish beta strip's X: closes it until the next day. Approved wording."))
        }
        .padding(.leading, 20)
        .padding(.trailing, 4)
        .frame(height: 44)
        .background {
            Color.black
                .ignoresSafeArea(edges: .top)
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(AppColors.gold.opacity(0.35))
                .frame(height: AppLine.hairline)
        }
        // A strip of chrome: held at the app's size whatever the phone's
        .dynamicTypeSize(...DynamicTypeSize.large)
    }
}

// MARK: - The sheet

/// The fuller notice: the first time the app opens in Spanish, and on a
/// tap of the strip
struct SpanishBetaSheet: View {
    let onDone: () -> Void

    @Environment(\.openURL) private var openURL

    /// Set when no mail app took the report's `mailto:` and the address
    /// was copied instead: a phone without Apple Mail, or with none set up
    @State private var copiedAddress = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                SheetHeader(
                    kicker: String(
                        localized: "Spanish · beta",
                        comment:
                            "Spanish beta notice sheet, its kicker over the title (uppercased on screen), shown only in Spanish"
                    ),
                    title: String(
                        localized: "Lumen Viae in Spanish",
                        comment: "Spanish beta notice sheet, its title, shown only in Spanish. Approved wording.")
                )

                VStack(alignment: .leading, spacing: 12) {
                    // The old one-time notice (`noticeWithBeta`), word for
                    // word, its two sentences as two paragraphs
                    Text(AppLanguage.translationNotice)
                    Text(AppLanguage.betaNotice)
                    Text(
                        "The Rosary's prayers and the prayers from Church sources were checked word for word. Texts translated with AI carry a small note that says so.",
                        comment:
                            "Spanish beta notice sheet, shown only in Spanish: what was checked by people, and that AI-translated texts carry a note. Approved wording."
                    )
                    Text(
                        "If you find a mistake, tell us.",
                        comment:
                            "Spanish beta notice sheet, shown only in Spanish: an invitation to report a mistake. Approved wording."
                    )
                }
                .font(AppFonts.readingFont(18))
                .lineSpacing(4)
                .foregroundColor(AppColors.cream.opacity(0.92))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, SheetMetrics.gutter)

                VStack(spacing: 0) {
                    Rectangle()
                        .fill(AppColors.textSecondary.opacity(0.2))
                        .frame(height: AppLine.hairline)
                        .padding(.horizontal, SheetMetrics.gutter)
                    Button {
                        guard let url = SpanishBeta.reportURL else { return }
                        // With no mail app to take it, the tap once did
                        // nothing at all: the address is copied instead,
                        // and the sheet says so beneath the row
                        openURL(url) { accepted in
                            guard !accepted else { return }
                            UIPasteboard.general.string = Constants.supportEmail
                            withAnimation(Motion.crossfade) { copiedAddress = true }
                            AccessibilityNotification.Announcement(
                                String(
                                    localized: "Address copied",
                                    comment: "Spanish beta notice sheet: VoiceOver announcement when the support address was copied because no mail app could open")
                            ).post()
                        }
                    } label: {
                        SheetRow(
                            String(
                                localized: "Report a mistake",
                                comment:
                                    "Spanish beta notice sheet: row that writes an email reporting a mistake in the Spanish"
                            ),
                            icon: "ph-chat-teardrop-text"
                        ) { SheetRowAccessoryView(accessory: .caret) }
                    }
                    .buttonStyle(.plain)
                    if copiedAddress {
                        Text(
                            "Mail couldn't open, so we copied our address: \(Constants.supportEmail). Paste it in your email app.",
                            comment:
                                "Spanish beta notice sheet, under Report a mistake when no mail app could open: the support address was copied to the clipboard"
                        )
                        .font(AppFonts.italicFont(15))
                        .foregroundColor(AppColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        // Under the row's name, as the line under Use the
                        // app in English stands, not under its glyph
                        .padding(.leading, SheetMetrics.gutter + 44)
                        .padding(.trailing, SheetMetrics.gutter)
                        .padding(.bottom, 10)
                        .transition(.opacity)
                    }
                    Button {
                        AppLanguage.openLanguageSettings()
                    } label: {
                        SheetRow(
                            String(
                                localized: "Use the app in English",
                                comment:
                                    "Spanish beta notice sheet: row that opens the system page where the app's language is chosen"
                            ),
                            icon: "ph-globe"
                        ) { SheetRowAccessoryView(accessory: .caret) }
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 18)

                GoldCTAButton(
                    title: String(localized: "Got it", comment: "Spanish beta notice sheet: the button that closes it"),
                    glyph: .none,
                    action: onDone
                )
                .padding(.horizontal, SheetMetrics.gutter)
                .padding(.top, 22)

                Text(
                    "Each day you will see a short notice at the top of the screen. You can close it.",
                    comment:
                        "Spanish beta notice sheet, under its button, shown only in Spanish: the strip comes back daily and can be closed. Approved wording."
                )
                .font(AppFonts.italicFont(15))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, SheetMetrics.gutter)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
        }
        .scrollBounceBehavior(.basedOnSize)
        .sheetGround()
        .presentationDetents([.large])
        .dynamicTypeSize(...DynamicTypeSize.appMaximum)
    }
}

// MARK: - Presented

extension View {
    /// The Spanish beta strip over a tab's root, and the sheet it opens
    func spanishBetaStrip(isShown: Bool, onOpen: @escaping () -> Void, onClose: @escaping () -> Void) -> some View {
        safeAreaInset(edge: .top, spacing: 0) {
            if isShown {
                SpanishBetaStrip(onOpen: onOpen, onClose: onClose)
                    .transition(.opacity)
            }
        }
    }
}
