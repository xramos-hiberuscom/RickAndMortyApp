//
//  GetCharacterUseCase.swift
//  RickAndMortyApp
//
//  Created by Xavier Ramos Sole on 25/11/2026.
//

import Foundation

protocol GetCharacterUseCaseContract {
    func execute(id: Int) async throws -> Character?
}

final class GetCharacterUseCase: GetCharacterUseCaseContract {
    private let repository: CharacterRepositoryContract
    
    init(repository: CharacterRepositoryContract = CharacterRepository()) {
        self.repository = repository
    }
    
    func execute(id: Int) async throws -> Character? {
        try await repository.getCharacter(id)
    }
}
