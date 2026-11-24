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
        Character(id: id, name: name, status: .alive, species: "Human", gender: .male, image: "")
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
}
