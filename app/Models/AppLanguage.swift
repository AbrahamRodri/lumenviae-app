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
import SwiftUI
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

    /// What the App Language row names: the language, and in Spanish that
    /// it is a beta ("Español (beta)", Abraham, 5 Nov 2026)
    static var rowName: String {
        guard isSpanish else { return name }
        return String(
            localized: "Spanish (beta)",
            comment: "Settings, App Language row, shown only in Spanish: the language's own name with beta after it")
    }

    /// Said in Spanish only, after the AI notice: Spanish is a beta, and
    /// what is still in English
    static var betaNotice: String {
        String(
            localized: "Spanish is in beta: the recordings and some meditations are still in English.",
            comment:
                "Shown only in Spanish, after the AI translation notice, at first launch and under the language row in Settings: Spanish is a beta, the narration recordings and some meditations are still English")
    }

    /// The AI notice as it is shown: the approved sentence, then the beta's
    static var noticeWithBeta: String { translationNotice + "\n\n" + betaNotice }

    // MARK: - The one-time notice

    private static let noticeShownKey = "appLanguage.translationNoticeShown"

    /// Owed the first time the app opens in Spanish, until its OK is
    /// pressed, and never again
    static func owesTranslationNotice(defaults: UserDefaults = .standard, inSpanish: Bool = isSpanish) -> Bool {
        inSpanish && !defaults.bool(forKey: noticeShownKey)
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

// MARK: - Dates

extension DateFormatter {
    /// A date drawn the way the design draws it in English ("MON 2 NOV"),
    /// and in the language's own order and words in any other ("lun, 2 nov"):
    /// English keeps its fixed pattern, every other language its locale's
    /// template.
    static func designed(english pattern: String, template: String) -> DateFormatter {
        let formatter = DateFormatter()
        if AppLanguage.code.hasPrefix("en") {
            formatter.dateFormat = pattern
        } else {
            formatter.setLocalizedDateFormatFromTemplate(template)
        }
        return formatter
    }
}

// MARK: - The notice, presented

extension View {
    /// The one-time AI translation notice. It counts as seen only once its
    /// OK is pressed: marked when raised, a notice SwiftUI never drew (a
    /// sheet came up in the same moment) was lost for good.
    func translationNotice(isPresented: Binding<Bool>, onDismiss: @escaping () -> Void = {}) -> some View {
        alert(
            Text("Translated with AI", comment: "Shown only in Spanish: title of the one-time notice at first launch that the app's words were translated with AI"),
            isPresented: isPresented
        ) {
            Button(String(localized: "OK", comment: "Button closing the one-time AI translation notice")) {
                AppLanguage.markTranslationNoticeShown()
                onDismiss()
            }
        } message: {
            Text(AppLanguage.noticeWithBeta)
        }
    }
}
