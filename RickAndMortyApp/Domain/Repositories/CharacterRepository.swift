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
    
    private let remoteDataSource: CharacterRemoteDataSourceContract
    
    // MARK: Methods
    
    init(remoteDataSource: CharacterRemoteDataSourceContract = CharacterRemoteDataSource()) {
        self.remoteDataSource = remoteDataSource
    }
    
    /// Returns the characters matching `name`.
    /// The API answers 404 when there are no matches, which is mapped to an empty list.
    func getCharacters(_ name: String) async throws -> [Character] {
        do {
            let response = try await remoteDataSource.getCharacters(name)
            return response.results.map { $0.convertToModel() }
        } catch NetworkError.notFound {
            return []
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
