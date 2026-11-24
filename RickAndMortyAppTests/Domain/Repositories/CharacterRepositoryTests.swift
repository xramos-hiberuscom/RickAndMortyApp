//
//  CharacterRepositoryTests.swift
//  RickAndMortyAppTests
//

import Foundation
import Testing
@testable import RickAndMortyApp

@MainActor
struct CharacterRepositoryTests {

    private let dataSource = CharacterRemoteDataSourceMock()
    private let sut: CharacterRepository

    init() {
        sut = CharacterRepository(remoteDataSource: dataSource)
    }

    private func serverCharacter(id: Int, name: String, status: String = "Alive", gender: String = "Male") -> ServerCharacter {
        ServerCharacter(id: id, name: name, status: status, species: "Human", gender: gender, image: "url\(id)")
    }

    @Test func passesNameToDataSource() async throws {
        _ = try await sut.getCharacters("rick")
        #expect(dataSource.receivedName == "rick")
    }

    @Test func mapsServerCharactersToDomain() async throws {
        dataSource.result = .success(ServerArray(
            info: ServerInformation(pages: 1),
            results: [serverCharacter(id: 1, name: "Rick Sanchez"),
                      serverCharacter(id: 2, name: "Birdperson", status: "Dead", gender: "Female")]
        ))

        let characters = try await sut.getCharacters("r")

        #expect(characters == [
            Character(id: 1, name: "Rick Sanchez", status: .alive, species: "Human", gender: .male, image: "url1"),
            Character(id: 2, name: "Birdperson", status: .dead, species: "Human", gender: .female, image: "url2")
        ])
    }

    @Test func unknownStatusAndGenderFallBackToUnknown() async throws {
        dataSource.result = .success(ServerArray(
            info: ServerInformation(pages: 1),
            results: [serverCharacter(id: 3, name: "Mystery", status: "???", gender: "???")]
        ))

        let character = try #require(try await sut.getCharacters("m").first)

        #expect(character.status == .unknown)
        #expect(character.gender == .unknown)
    }

    @Test func returnsEmptyListWhenNothingFound() async throws {
        dataSource.result = .failure(NetworkError.notFound)
        let characters = try await sut.getCharacters("zzzz")
        #expect(characters.isEmpty)
    }

    @Test func propagatesOtherErrors() async {
        dataSource.result = .failure(NetworkError.statusCode(500))
        await #expect(throws: NetworkError.statusCode(500)) { _ = try await sut.getCharacters("rick") }
    }
}
