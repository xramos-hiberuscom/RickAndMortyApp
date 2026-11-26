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
    /// A further page is being fetched (the list stays visible).
    private(set) var isLoadingMore = false
    /// Fetching a further page failed; the list stays and the user can retry.
    private(set) var loadMoreFailed = false
    /// Whether there are further pages to load.
    var canLoadMore: Bool { nextPage != nil }

    @ObservationIgnored private let useCase: SearchCharactersUseCaseContract
    @ObservationIgnored private let debounce: Duration
    @ObservationIgnored private(set) var searchTask: Task<Void, Never>?
    @ObservationIgnored private(set) var loadMoreTask: Task<Void, Never>?
    /// Page to request next, or `nil` when there are no more pages.
    private var nextPage: Int?
    /// Query of the results currently shown.
    @ObservationIgnored private var currentName = ""

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
        resetPagination()

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
                let page = try await useCase.execute(name: name, page: 1)
                try Task.checkCancellation()
                currentName = name
                nextPage = page.hasNextPage ? page.page + 1 : nil
                state = page.characters.isEmpty ? .empty : .loaded(page.characters)
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

    // MARK: - Pagination

    /// Call when a row appears: loads the next page once the last loaded character is reached.
    func loadMoreIfNeeded(after character: Character) {
        guard case .loaded(let characters) = state, characters.last?.id == character.id else { return }
        loadMore()
    }

    /// Fetches the next page and appends it. Does nothing if there is none or one is already loading.
    /// Like a search, it is cancelled by a new search and a cancelled one never publishes.
    ///
    /// A page that brings nothing new (404, empty, or only characters already shown) means the list
    /// is complete: pagination ends silently. Only real failures show the retry option.
    func loadMore() {
        guard let page = nextPage, !isLoadingMore, case .loaded = state else { return }

        isLoadingMore = true
        loadMoreFailed = false
        let name = currentName

        loadMoreTask = Task { [useCase] in
            do {
                let result = try await useCase.execute(name: name, page: page)
                try Task.checkCancellation()
                guard case .loaded(let existing) = state else { return }
                let known = Set(existing.map(\.id))
                let fresh = result.characters.filter { !known.contains($0.id) }
                if fresh.isEmpty {
                    nextPage = nil
                } else {
                    state = .loaded(existing + fresh)
                    nextPage = result.hasNextPage ? page + 1 : nil
                }
                isLoadingMore = false
            } catch is CancellationError {
                // Superseded by a new search, which resets the pagination state.
            } catch NetworkError.transport(.cancelled) {
                // URLSession reports a cancelled request as a transport error.
            } catch NetworkError.notFound {
                // The API has no such page: the list is complete, not an error.
                guard !Task.isCancelled else { return }
                nextPage = nil
                isLoadingMore = false
            } catch {
                guard !Task.isCancelled else { return }
                isLoadingMore = false
                loadMoreFailed = true
            }
        }
    }

    private func resetPagination() {
        loadMoreTask?.cancel()
        loadMoreTask = nil
        nextPage = nil
        currentName = ""
        isLoadingMore = false
        loadMoreFailed = false
    }
}
