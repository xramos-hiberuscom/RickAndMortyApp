//
//  CharacterRepository.swift
//  RickAndMortyApp
//
//  Created by Xavier Ramos Sole on 24/11/2026.
//

import Foundation

protocol CharacterRepositoryContract {
    func getCharacters(_ name: String, page: Int) async throws -> CharactersPage
    func getCharacter(_ id: Int) async throws -> Character?
}

final class CharacterRepository: CharacterRepositoryContract {
 
    // MARK: Variables
    
    /// How long the results of a search stay valid.
    static let searchCacheTTL: TimeInterval = 2 * 60

    /// Cache key: normalised query + page.
    nonisolated struct SearchKey: Hashable {
        let name: String
        let page: Int
    }

    private let remoteDataSource: CharacterRemoteDataSourceContract
    private let searchCache: TimedCache<SearchKey, CharactersPage>
    
    // MARK: Methods
    
    init(remoteDataSource: CharacterRemoteDataSourceContract = CharacterRemoteDataSource(),
         searchCache: TimedCache<SearchKey, CharactersPage> = TimedCache(ttl: CharacterRepository.searchCacheTTL)) {
        self.remoteDataSource = remoteDataSource
        self.searchCache = searchCache
    }
    
    /// Returns one page of the characters matching `name`.
    /// Each (query, page) is cached for `searchCacheTTL`: while valid it is returned without a network call.
    /// The API answers 404 when there are no matches (or no such page), which is mapped, and cached,
    /// as an empty page without next page.
    func getCharacters(_ name: String, page: Int) async throws -> CharactersPage {
        let key = SearchKey(name: name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
                            page: page)

        if let cached = searchCache.value(for: key) {
            return cached
        }

        let result: CharactersPage
        do {
            let response = try await remoteDataSource.getCharacters(name, page: page)
            result = CharactersPage(characters: response.results.map { $0.convertToModel() },
                                    page: page,
                                    hasNextPage: page < response.info.pages)
        } catch NetworkError.notFound {
            result = CharactersPage(characters: [], page: page, hasNextPage: false)
        }

        searchCache.store(result, for: key)
        return result
    }

    /// Returns the character with the given `id`, or `nil` when it does not exist (HTTP 404).
    func getCharacter(_ id: Int) async throws -> Character? {
        do {
            return try await remoteDataSource.getCharacter(id).convertToModel()
        } catch NetworkError.notFound {
            return nil
        }
    }
}
