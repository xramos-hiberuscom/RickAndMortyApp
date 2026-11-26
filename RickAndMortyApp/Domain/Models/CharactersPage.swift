//
//  CharactersPage.swift
//  RickAndMortyApp
//

import Foundation

/// One page of search results.
struct CharactersPage: Equatable {
    let characters: [Character]
    let page: Int
    /// Whether the API has more pages after this one.
    let hasNextPage: Bool
}
