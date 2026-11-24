//
//  CharacterRemoteDataSourceTests.swift
//  RickAndMortyAppTests
//

import Foundation
import Testing
@testable import RickAndMortyApp

@MainActor
struct CharacterRemoteDataSourceTests {

    @Test func requestsCharacterFilterByName() async throws {
        let mock = NetworkManagerMock()
        let character = ServerCharacter(id: 1, name: "Rick Sanchez", status: "Alive",
                                        species: "Human", gender: "Male", image: "url")
        mock.result = .success(ServerArray(info: ServerInformation(pages: 3), results: [character]))
        let sut = CharacterRemoteDataSource(networkManager: mock)

        let response = try await sut.getCharacters("rick")

        let url = try mock.receivedEndpoint?.urlRequest().url?.absoluteString
        #expect(url == "https://rickandmortyapi.com/api/character?name=rick")
        #expect(response.results.first?.name == "Rick Sanchez")
        #expect(response.info.pages == 3)
    }

    @Test func propagatesNotFound() async {
        let mock = NetworkManagerMock()
        mock.result = .failure(.notFound)
        let sut = CharacterRemoteDataSource(networkManager: mock)

        await #expect(throws: NetworkError.notFound) { _ = try await sut.getCharacters("zzzz") }
    }
}
