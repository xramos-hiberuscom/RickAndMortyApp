//
//  CharacterRepository.swift
//  RickAndMortyApp
//
//  Created by Xavier Ramos Sole on 24/11/2026.
//

import Foundation

protocol CharacterRepositoryContract {
    func getCharacters(_ name: String) async throws -> [Character]
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
            return response.results.map { $0.convertToEntity() }
        } catch NetworkError.notFound {
            return []
        }
    }
}
