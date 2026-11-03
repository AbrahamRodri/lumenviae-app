//
//  AppLanguage.swift
//  app
//
//  The language the app's own words are shown in. The app follows the
//  phone's language; Settings opens the system's page for this app, where
//  a person can choose Español or English for Lumen Viae alone.
//
//  Spanish carries a notice that its words were translated with AI
//  (approved by Abraham, 2 November 2026): once, the first time the app
//  opens in Spanish, and always under the language row in Settings.
//

import Foundation
import UIKit

enum AppLanguage {

    /// The localization the app is showing, as the bundle resolved it
    /// from the phone's (or this app's own) language choice
    static var code: String {
        Bundle.main.preferredLocalizations.first ?? "en"
    }

    static var isSpanish: Bool { code.hasPrefix("es") }

    /// The language's own name, in that language: "English", "Español"
    static var name: String {
        let locale = Locale(identifier: code)
        let name = locale.localizedString(forLanguageCode: code) ?? code
        return name.prefix(1).uppercased(with: locale) + name.dropFirst()
    }

    /// Said in Spanish only; an English reader never sees it
    static var translationNotice: String {
        String(
            localized:
                "The words of this app were translated into Spanish with artificial intelligence. The prayers use the Church's traditional texts.",
            comment:
                "Shown only in Spanish: the notice that the app's words were translated with AI, once at first launch and under the language row in Settings. Approved wording; translate exactly as approved."
        )
    }

    // MARK: - The one-time notice

    private static let noticeShownKey = "appLanguage.translationNoticeShown"

    /// Owed the first time the app opens in Spanish, and never again
    static func owesTranslationNotice(defaults: UserDefaults = .standard) -> Bool {
        isSpanish && !defaults.bool(forKey: noticeShownKey)
    }

    static func markTranslationNoticeShown(defaults: UserDefaults = .standard) {
        defaults.set(true, forKey: noticeShownKey)
    }

    // MARK: - Choosing

    /// The system's own page for this app, where its language is chosen
    @MainActor
    static func openLanguageSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
