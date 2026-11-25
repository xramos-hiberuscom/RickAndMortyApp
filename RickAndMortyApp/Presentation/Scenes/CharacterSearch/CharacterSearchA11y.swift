//
//  CharacterSearchA11y.swift
//  RickAndMortyApp
//
//  Created by Xavier Ramos Sole on 25/11/2026.
//

import Foundation

/// Accessibility Identifiers and Labels
struct CharacterSearchA11y {

    static func identifier(of id: Int) -> String {
        "character-row-\(id)"
    }

    static let loading = "Searching characters"
    static let rowHint = "Shows character details"

    static func resultsAnnouncement(count: Int) -> String {
        count == 1 ? "1 character found" : "\(count) characters found"
    }

    static let noResultsAnnouncement = "No characters found"
}
