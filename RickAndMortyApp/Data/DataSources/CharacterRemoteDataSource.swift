//
//  CharacterRemoteDataSource.swift
//  RickAndMortyApp
//
//  Created by Xavier Ramos Sole on 24/11/2026.
//

import Foundation

protocol CharacterRemoteDataSourceContract {
    func getCharacters(_ name: String) async throws -> ServerArray<ServerCharacter>
}

final class CharacterRemoteDataSource: CharacterRemoteDataSourceContract {

    // MARK: - Variables

    private let networkManager: NetworkManagerContract

    // MARK: - Methods

    init(networkManager: NetworkManagerContract = NetworkManager()) {
        self.networkManager = networkManager
    }

    /// Filters characters by name: `GET /character?name={name}`.
    /// Throws `NetworkError.notFound` when the API finds no matches (HTTP 404).
    func getCharacters(_ name: String) async throws -> ServerArray<ServerCharacter> {
        try await networkManager.perform(.characters(name: name))
    }
}
