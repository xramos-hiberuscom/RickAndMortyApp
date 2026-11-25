//
//  CharacterRepository.swift
//  RickAndMortyApp
//
//  Created by Xavier Ramos Sole on 24/11/2026.
//

import Foundation

protocol CharacterRepositoryContract {
    func getCharacters(_ name: String) async throws -> [Character]
    func getCharacter(_ id: Int) async throws -> Character?
}

final class CharacterRepository: CharacterRepositoryContract {
 
    // MARK: Variables
    
    /// How long the results of a search stay valid.
    static let searchCacheTTL: TimeInterval = 2 * 60

    private let remoteDataSource: CharacterRemoteDataSourceContract
    private let searchCache: TimedCache<String, [Character]>
    
    // MARK: Methods
    
    init(remoteDataSource: CharacterRemoteDataSourceContract = CharacterRemoteDataSource(),
         searchCache: TimedCache<String, [Character]> = TimedCache(ttl: CharacterRepository.searchCacheTTL)) {
        self.remoteDataSource = remoteDataSource
        self.searchCache = searchCache
    }
    
    /// Returns the characters matching `name`.
    /// Results are cached per query for `searchCacheTTL`: while valid they are returned without a network call.
    /// The API answers 404 when there are no matches, which is mapped (and cached) as an empty list.
    func getCharacters(_ name: String) async throws -> [Character] {
        let key = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        if let cached = searchCache.value(for: key) {
            return cached
        } else {
            let characters: [Character]
            do {
                let response = try await remoteDataSource.getCharacters(name)
                characters = response.results.map { $0.convertToModel() }
            } catch NetworkError.notFound {
                characters = []
            }
            
            searchCache.store(characters, for: key)
            return characters
        }
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
