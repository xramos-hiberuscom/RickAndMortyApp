//
//  SearchCharactersUseCase.swift
//  RickAndMortyApp
//
//  Created by Xavier Ramos Sole on 24/11/2026.
//

import Foundation

protocol SearchCharactersUseCaseContract {
    func execute(name: String, page: Int) async throws -> CharactersPage
}

final class SearchCharactersUseCase: SearchCharactersUseCaseContract {
    private let repository: CharacterRepositoryContract
    
    init(repository: CharacterRepositoryContract = CharacterRepository()) {
        self.repository = repository
    }
    
    func execute(name: String, page: Int) async throws -> CharactersPage {
        try await repository.getCharacters(name, page: page)
    }
}
