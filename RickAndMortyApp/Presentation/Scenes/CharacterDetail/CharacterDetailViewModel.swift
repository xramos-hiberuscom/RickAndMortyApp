//
//  CharacterDetailViewModel.swift
//  RickAndMortyApp
//
//  Created by Xavier Ramos Sole on 25/11/2026.
//

import Foundation
import Observation

@Observable
final class CharacterDetailViewModel {

    enum State: Equatable {
        case loading
        case loaded(Character)
        case notFound
        case error(String)
    }

    // MARK: - Variables

    private(set) var state: State = .loading

    @ObservationIgnored let characterId: Int
    @ObservationIgnored private let useCase: GetCharacterUseCaseContract

    // MARK: - Methods

    init(characterId: Int,
         useCase: GetCharacterUseCaseContract = GetCharacterUseCase()) {
        self.characterId = characterId
        self.useCase = useCase
    }

    /// Loads the character by id. Can be called again to retry after an error.
    func load() async {
        state = .loading
        do {
            let character = try await useCase.execute(id: characterId)
            try Task.checkCancellation()
            state = character.map(State.loaded) ?? .notFound
        } catch is CancellationError {
            // The view went away: nothing to publish.
        } catch NetworkError.transport(.cancelled) {
            // URLSession reports a cancelled request as a transport error.
        } catch {
            guard !Task.isCancelled else { return }
            state = .error(error.localizedDescription)
        }
    }
}
