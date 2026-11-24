//
//  CharacterSearchViewModel.swift
//  RickAndMortyApp
//
//  Created by Xavier Ramos Sole on 24/11/2026.
//

import Foundation
import Observation

@Observable
final class CharacterSearchViewModel {

    enum State: Equatable {
        case idle
        case loading
        case loaded([Character])
        case empty
        case error(String)
    }

    // MARK: - Variables

    var query = ""
    private(set) var state: State = .idle

    @ObservationIgnored private let useCase: SearchCharactersUseCaseContract
    @ObservationIgnored private let debounce: Duration
    @ObservationIgnored private(set) var searchTask: Task<Void, Never>?

    // MARK: - Methods

    init(useCase: SearchCharactersUseCaseContract = SearchCharactersUseCase(),
         debounce: Duration = .milliseconds(300)) {
        self.useCase = useCase
        self.debounce = debounce
    }

    /// Starts a search, cancelling any search still in flight.
    /// Results of a cancelled search are never published, even if its request completes.
    func search(_ text: String) {
        searchTask?.cancel()

        let name = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            searchTask = nil
            state = .idle
            return
        }

        state = .loading
        searchTask = Task { [useCase, debounce] in
            do {
                try await Task.sleep(for: debounce)
                let characters = try await useCase.execute(name: name)
                try Task.checkCancellation()
                state = characters.isEmpty ? .empty : .loaded(characters)
            } catch is CancellationError {
                // Superseded by a newer search: leave the state to it.
            } catch NetworkError.transport(.cancelled) {
                // URLSession reports a cancelled request as a transport error.
            } catch {
                guard !Task.isCancelled else { return }
                state = .error(error.localizedDescription)
            }
        }
    }
}
