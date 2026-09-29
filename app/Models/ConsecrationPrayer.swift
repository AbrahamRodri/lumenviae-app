//
//  ConsecrationPrayer.swift
//  Lumen Viae
//
//  A single prayer recited daily within a consecration phase,
//  e.g. Veni Creator, Ave Maris Stella, Magnificat, the litanies.
//

import Foundation

struct ConsecrationPrayer: Codable, Identifiable, Hashable {

    // MARK: - Properties

    /// Unique identifier for the prayer (e.g., "veni_creator", "magnificat")
    let id: String

    /// English title of the prayer (e.g., "Come, Creator Spirit")
    let title: String

    /// Latin title if applicable (e.g., "Veni Creator Spiritus")
    let latinTitle: String?

    /// Full text of the prayer. A prayer that is sung has its chant in the
    /// Chant Library (`ChantCatalog.chants(forPrayer:)`), found by its id.
    let content: String

    // MARK: - Initializer

    init(
        id: String,
        title: String,
        latinTitle: String? = nil,
        content: String
    ) {
        self.id = id
        self.title = title
        self.latinTitle = latinTitle
        self.content = content
    }

    // MARK: - Computed Properties

    /// Display title - uses Latin title if available, otherwise English
    var displayTitle: String {
        latinTitle ?? title
    }
}

