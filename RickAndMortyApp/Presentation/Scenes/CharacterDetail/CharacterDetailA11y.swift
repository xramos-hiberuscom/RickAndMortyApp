//
//  CharacterDetailA11y.swift
//  RickAndMortyApp
//
//  Created by Xavier Ramos Sole on 25/11/2026.
//

import Foundation

/// Accessibility Identifiers and Labels
struct CharacterDetailA11y {
    static let identifier = "character-detail"
    
    static let loading = "Loading character"

    static func photo(of name: String) -> String {
        "Photo of \(name)"
    }
}
