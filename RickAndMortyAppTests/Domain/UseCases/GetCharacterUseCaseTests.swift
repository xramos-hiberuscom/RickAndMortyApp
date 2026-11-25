//
//  GetCharacterUseCaseTests.swift
//  RickAndMortyAppTests
//

import Foundation
import Testing
@testable import RickAndMortyApp

@MainActor
struct GetCharacterUseCaseTests {

    private let repository = CharacterRepositoryMock()
    private let sut: GetCharacterUseCase

    init() {
        sut = GetCharacterUseCase(repository: repository)
    }

    private let rick = Character(id: 1,
                                 name: "Rick Sanchez",
                                 status: .alive,
                                 species: "Human",
                                 gender: .male,
                                 image: "url1")

    @Test func passesIdToRepository() async throws {
        _ = try await sut.execute(id: 42)
        #expect(repository.requestedId == 42)
    }

    @Test func returnsRepositoryCharacter() async throws {
        repository.characterResult = .success(rick)
        let character = try await sut.execute(id: 1)
        #expect(character == rick)
    }

    @Test func returnsNilWhenCharacterDoesNotExist() async throws {
        repository.characterResult = .success(nil)
        let character = try await sut.execute(id: 99999)
        #expect(character == nil)
    }

    @Test func propagatesRepositoryErrors() async {
        repository.characterResult = .failure(NetworkError.statusCode(500))
        await #expect(throws: NetworkError.statusCode(500)) { _ = try await sut.execute(id: 1) }
    }
}
