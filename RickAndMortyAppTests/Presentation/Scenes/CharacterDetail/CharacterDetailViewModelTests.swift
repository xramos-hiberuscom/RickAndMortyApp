//
//  CharacterDetailViewModelTests.swift
//  RickAndMortyAppTests
//

import Foundation
import Testing
@testable import RickAndMortyApp

@MainActor
struct CharacterDetailViewModelTests {

    private let useCase = GetCharacterUseCaseMock()
    private let sut: CharacterDetailViewModel

    init() {
        sut = CharacterDetailViewModel(characterId: 1, useCase: useCase)
    }

    private let rick = Character(id: 1, name: "Rick Sanchez", status: .alive, species: "Human",
                                 gender: .male, image: "url1")

    @Test func startsLoading() {
        #expect(sut.state == .loading)
    }

    @Test func requestsCharacterById() async {
        await sut.load()
        #expect(useCase.requestedIds == [1])
    }

    @Test func loadsCharacter() async {
        useCase.result = .success(rick)
        await sut.load()
        #expect(sut.state == .loaded(rick))
    }

    @Test func showsNotFoundWhenCharacterDoesNotExist() async {
        useCase.result = .success(nil)
        await sut.load()
        #expect(sut.state == .notFound)
    }

    @Test func showsErrorOnFailure() async {
        useCase.result = .failure(NetworkError.statusCode(500))
        await sut.load()
        #expect(sut.state == .error(NetworkError.statusCode(500).localizedDescription))
    }

    @Test func retryAfterErrorLoadsCharacter() async {
        useCase.result = .failure(NetworkError.transport(.notConnectedToInternet))
        await sut.load()

        useCase.result = .success(rick)
        await sut.load()

        #expect(sut.state == .loaded(rick))
        #expect(useCase.requestedIds == [1, 1])
    }

    @Test func cancelledLoadDoesNotShowError() async {
        useCase.result = .failure(NetworkError.transport(.cancelled))
        await sut.load()
        #expect(sut.state == .loading)
    }

    @Test func cancellationErrorDoesNotShowError() async {
        useCase.result = .failure(CancellationError())
        await sut.load()
        #expect(sut.state == .loading)
    }
}
