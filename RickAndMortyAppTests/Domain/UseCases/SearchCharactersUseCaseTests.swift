//
//  SearchCharactersUseCaseTests.swift
//  RickAndMortyAppTests
//

import Foundation
import Testing
@testable import RickAndMortyApp

@MainActor
struct SearchCharactersUseCaseTests {

    private let repository = CharacterRepositoryMock()
    private let sut: SearchCharactersUseCase

    init() {
        sut = SearchCharactersUseCase(repository: repository)
    }

    private func character(_ id: Int, _ name: String) -> Character {
        Character(id: id, name: name, status: .alive, species: "Human", gender: .male, image: "")
    }

    private func waitUntil(_ condition: () -> Bool) async {
        for _ in 0..<1000 where !condition() { await Task.yield() }
    }

    @Test func returnsRepositoryCharactersForName() async throws {
        let task = Task { try await sut.execute(name: "rick", page: 1) }
        await waitUntil { repository.isPending("rick") }

        repository.resolve("rick", with: .success([character(1, "Rick")]))

        #expect(try await task.value == CharactersPage(characters: [character(1, "Rick")], page: 1, hasNextPage: false))
        #expect(repository.requestedNames == ["rick"])
    }

    @Test func propagatesRepositoryErrors() async {
        let task = Task { try await sut.execute(name: "rick", page: 1) }
        await waitUntil { repository.isPending("rick") }

        repository.resolve("rick", with: .failure(NetworkError.statusCode(500)))

        await #expect(throws: NetworkError.statusCode(500)) { _ = try await task.value }
    }

    @Test func forwardsThePageToTheRepository() async throws {
        let task = Task { try await sut.execute(name: "rick", page: 2) }
        await waitUntil { repository.isPending("rick", page: 2) }

        repository.resolve("rick", page: 2, hasNextPage: true, with: .success([character(21, "Rick 21")]))

        let page = try await task.value
        #expect(repository.requestedPages == [2])
        #expect(page == CharactersPage(characters: [character(21, "Rick 21")], page: 2, hasNextPage: true))
    }
}
