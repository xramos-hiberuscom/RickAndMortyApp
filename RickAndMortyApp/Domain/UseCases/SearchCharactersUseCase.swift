//
//  SearchCharactersUseCase.swift
//  RickAndMortyApp
//
//  Created by Xavier Ramos Sole on 24/11/2026.
//

import Foundation

protocol SearchCharactersUseCaseContract {
    func execute(name: String) async throws -> [Character]
}

final class SearchCharactersUseCase: SearchCharactersUseCaseContract {
    private let repository: CharacterRepositoryContract
    
    init(repository: CharacterRepositoryContract = CharacterRepository()) {
        self.repository = repository
    }
    
    func execute(name: String) async throws -> [Character] {
        try await repository.getCharacters(name)
    }
}
