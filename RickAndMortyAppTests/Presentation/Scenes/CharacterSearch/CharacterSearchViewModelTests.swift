//
//  CharacterSearchViewModelTests.swift
//  RickAndMortyAppTests
//

import Foundation
import Testing
@testable import RickAndMortyApp

@MainActor
struct CharacterSearchViewModelTests {

    private let useCase = SearchCharactersUseCaseMock()
    private let sut: CharacterSearchViewModel

    init() {
        sut = CharacterSearchViewModel(useCase: useCase, debounce: .zero)
    }

    private func character(_ id: Int, _ name: String) -> Character {
        Character(id: id,
                  name: name,
                  status: .alive,
                  species: "Human",
                  gender: .male,
                  image: "")
    }

    private func waitUntil(_ condition: () -> Bool) async {
        for _ in 0..<1000 where !condition() { await Task.yield() }
    }

    @Test func startsIdle() {
        #expect(sut.state == .idle)
    }

    @Test func loadsCharacters() async {
        sut.search("rick")
        #expect(sut.state == .loading)
        await waitUntil { useCase.isPending("rick") }

        useCase.resolve("rick", with: .success([character(1, "Rick")]))
        await sut.searchTask?.value

        #expect(sut.state == .loaded([character(1, "Rick")]))
    }

    @Test func emptyResultShowsEmptyState() async {
        sut.search("zzzz")
        await waitUntil { useCase.isPending("zzzz") }

        useCase.resolve("zzzz", with: .success([]))
        await sut.searchTask?.value

        #expect(sut.state == .empty)
    }

    @Test func failureShowsError() async {
        sut.search("rick")
        await waitUntil { useCase.isPending("rick") }

        useCase.resolve("rick", with: .failure(NetworkError.statusCode(500)))
        await sut.searchTask?.value

        #expect(sut.state == .error(NetworkError.statusCode(500).localizedDescription))
    }

    @Test func newSearchCancelsPreviousAndDiscardsItsResults() async {
        sut.search("rick")
        let first = sut.searchTask
        await waitUntil { useCase.isPending("rick") }

        sut.search("morty")
        await waitUntil { useCase.isPending("morty") }
        #expect(first?.isCancelled == true)

        // The newer search finishes first...
        useCase.resolve("morty", with: .success([character(2, "Morty")]))
        await sut.searchTask?.value
        // ...then the cancelled one completes late with stale data.
        useCase.resolve("rick", with: .success([character(1, "Rick")]))
        await first?.value

        #expect(sut.state == .loaded([character(2, "Morty")]))
    }

    @Test func cancelledSearchErrorIsNotShown() async {
        sut.search("rick")
        let first = sut.searchTask
        await waitUntil { useCase.isPending("rick") }

        sut.search("morty")
        useCase.resolve("rick", with: .failure(NetworkError.transport(.cancelled)))
        await first?.value

        #expect(sut.state == .loading)
    }

    @Test func clearingQueryCancelsSearchAndResetsToIdle() async {
        sut.search("rick")
        let first = sut.searchTask
        await waitUntil { useCase.isPending("rick") }

        sut.search("   ")
        useCase.resolve("rick", with: .success([character(1, "Rick")]))
        await first?.value

        #expect(sut.state == .idle)
    }

    @Test func trimsQueryBeforeSearching() async {
        sut.search("  rick ")
        await waitUntil { useCase.isPending("rick") }

        #expect(useCase.requestedNames == ["rick"])
        useCase.resolve("rick", with: .success([]))
        await sut.searchTask?.value
    }

    // MARK: - Pagination

    /// Runs a search whose first page reports more pages and waits until it is loaded.
    private func loadFirstPage(of name: String = "rick", hasNextPage: Bool = true) async {
        sut.search(name)
        await waitUntil { useCase.isPending(name) }
        useCase.resolve(name, hasNextPage: hasNextPage, with: .success([character(1, "Rick 1"), character(2, "Rick 2")]))
        await sut.searchTask?.value
    }

    private func loadSecondPage(_ result: Result<[Character], Error>, hasNextPage: Bool = false) async {
        sut.loadMore()
        await waitUntil { useCase.isPending("rick", page: 2) }
        useCase.resolve("rick", page: 2, hasNextPage: hasNextPage, with: result)
        await sut.loadMoreTask?.value
    }

    @Test func firstSearchRequestsPageOne() async {
        await loadFirstPage()

        #expect(useCase.requestedPages == [1])
    }

    @Test func loadingMoreAppendsTheNextPage() async {
        await loadFirstPage()

        sut.loadMore()
        #expect(sut.isLoadingMore)
        await waitUntil { useCase.isPending("rick", page: 2) }
        useCase.resolve("rick", page: 2, with: .success([character(3, "Rick 3")]))
        await sut.loadMoreTask?.value

        #expect(sut.state == .loaded([character(1, "Rick 1"), character(2, "Rick 2"), character(3, "Rick 3")]))
        #expect(!sut.isLoadingMore)
        #expect(useCase.requestedPages == [1, 2])
    }

    @Test func reachingTheLastCharacterLoadsMore() async {
        await loadFirstPage()

        sut.loadMoreIfNeeded(after: character(1, "Rick 1"))
        #expect(!sut.isLoadingMore, "Only the last row should trigger loading")

        sut.loadMoreIfNeeded(after: character(2, "Rick 2"))
        #expect(sut.isLoadingMore)
        await waitUntil { useCase.isPending("rick", page: 2) }
        useCase.resolve("rick", page: 2, with: .success([character(3, "Rick 3")]))
        await sut.loadMoreTask?.value
    }

    @Test func doesNotLoadMoreOnTheLastPage() async {
        await loadFirstPage(hasNextPage: false)

        sut.loadMore()

        #expect(!sut.isLoadingMore)
        #expect(!sut.canLoadMore)
        #expect(useCase.requestedPages == [1])
    }

    @Test func doesNotStartSecondLoadWhileOneIsInFlight() async {
        await loadFirstPage()

        sut.loadMore()
        sut.loadMore()
        await waitUntil { useCase.isPending("rick", page: 2) }

        #expect(useCase.requestedPages == [1, 2])
        useCase.resolve("rick", page: 2, with: .success([character(3, "Rick 3")]))
        await sut.loadMoreTask?.value
    }

    @Test func pagesChainUntilTheLastOne() async {
        await loadFirstPage()
        await loadSecondPage(.success([character(3, "Rick 3")]), hasNextPage: true)

        sut.loadMore()
        await waitUntil { useCase.isPending("rick", page: 3) }
        useCase.resolve("rick", page: 3, hasNextPage: false, with: .success([character(4, "Rick 4")]))
        await sut.loadMoreTask?.value

        sut.loadMore()
        #expect(!sut.isLoadingMore, "No page after the last one")
        #expect(useCase.requestedPages == [1, 2, 3])
    }

    @Test func duplicatedCharactersAcrossPagesAreIgnored() async {
        await loadFirstPage()

        await loadSecondPage(.success([character(2, "Rick 2"), character(3, "Rick 3")]))

        #expect(sut.state == .loaded([character(1, "Rick 1"), character(2, "Rick 2"), character(3, "Rick 3")]))
    }

    // MARK: - Pages without new results are not errors

    @Test func notFoundWhileLoadingMoreEndsPaginationWithoutError() async {
        await loadFirstPage()

        await loadSecondPage(.failure(NetworkError.notFound))

        #expect(sut.state == .loaded([character(1, "Rick 1"), character(2, "Rick 2")]))
        #expect(!sut.loadMoreFailed)
        #expect(!sut.canLoadMore)
        #expect(!sut.isLoadingMore)
    }

    @Test func emptyPageEndsPaginationWithoutError() async {
        await loadFirstPage()

        await loadSecondPage(.success([]), hasNextPage: true)

        #expect(sut.state == .loaded([character(1, "Rick 1"), character(2, "Rick 2")]))
        #expect(!sut.loadMoreFailed)
        #expect(!sut.canLoadMore, "An empty page must not keep requesting further pages")
    }

    @Test func pageWithOnlyKnownCharactersEndsPaginationWithoutError() async {
        await loadFirstPage()

        await loadSecondPage(.success([character(1, "Rick 1"), character(2, "Rick 2")]), hasNextPage: true)

        #expect(sut.state == .loaded([character(1, "Rick 1"), character(2, "Rick 2")]))
        #expect(!sut.loadMoreFailed)
        #expect(!sut.canLoadMore)
    }

    @Test func realFailureWhileLoadingMoreKeepsListAndAllowsRetry() async {
        await loadFirstPage()

        await loadSecondPage(.failure(NetworkError.statusCode(500)))

        #expect(sut.state == .loaded([character(1, "Rick 1"), character(2, "Rick 2")]))
        #expect(sut.loadMoreFailed)
        #expect(sut.canLoadMore)
        #expect(!sut.isLoadingMore)

        await loadSecondPage(.success([character(3, "Rick 3")]))

        #expect(!sut.loadMoreFailed)
        #expect(sut.state == .loaded([character(1, "Rick 1"), character(2, "Rick 2"), character(3, "Rick 3")]))
    }

    // MARK: - Cancellation

    @Test func newSearchCancelsLoadMoreAndDiscardsItsResults() async {
        await loadFirstPage()
        sut.loadMore()
        let loadMore = sut.loadMoreTask
        await waitUntil { useCase.isPending("rick", page: 2) }

        sut.search("morty")
        #expect(loadMore?.isCancelled == true)
        #expect(!sut.isLoadingMore)

        await waitUntil { useCase.isPending("morty") }
        useCase.resolve("morty", with: .success([character(9, "Morty")]))
        await sut.searchTask?.value
        // The cancelled page-2 request completes late with stale data.
        useCase.resolve("rick", page: 2, with: .success([character(3, "Rick 3")]))
        await loadMore?.value

        #expect(sut.state == .loaded([character(9, "Morty")]))
    }

    @Test func clearingQueryResetsPagination() async {
        await loadFirstPage()

        sut.search("")
        sut.loadMore()

        #expect(sut.state == .idle)
        #expect(!sut.isLoadingMore)
        #expect(useCase.requestedPages == [1])
    }

    @Test func cancelledLoadMoreErrorIsNotShown() async {
        await loadFirstPage()
        sut.loadMore()
        let loadMore = sut.loadMoreTask
        await waitUntil { useCase.isPending("rick", page: 2) }

        sut.search("morty")
        useCase.resolve("rick", page: 2, with: .failure(NetworkError.transport(.cancelled)))
        await loadMore?.value

        #expect(!sut.loadMoreFailed)
    }
}
