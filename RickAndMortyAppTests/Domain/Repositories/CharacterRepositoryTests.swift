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
    private let clock = TestClock()
    private let sut: CharacterRepository

    init() {
        let clock = clock
        sut = CharacterRepository(remoteDataSource: dataSource,
                                  searchCache: TimedCache(ttl: CharacterRepository.searchCacheTTL,
                                                          now: { clock.now }))
    }

    private func serverCharacter(id: Int,
                                 name: String,
                                 status: String = "Alive",
                                 gender: String = "Male") -> ServerCharacter {
        ServerCharacter(id: id,
                        name: name,
                        status: status,
                        species: "Human",
                        gender: gender,
                        image: "url\(id)")
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
            Character(id: 1,
                      name: "Rick Sanchez",
                      status: .alive,
                      species: "Human",
                      gender: .male,
                      image: "url1"),
            Character(id: 2,
                      name: "Birdperson",
                      status: .dead,
                      species: "Human",
                      gender: .female,
                      image: "url2")
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

    // MARK: - getCharacter

    @Test func getCharacterPassesIdToDataSource() async throws {
        dataSource.characterResult = .success(serverCharacter(id: 7, name: "Rick"))
        _ = try await sut.getCharacter(7)
        #expect(dataSource.receivedId == 7)
    }

    @Test func getCharacterMapsToDomain() async throws {
        dataSource.characterResult = .success(serverCharacter(id: 2, name: "Birdperson", status: "Dead", gender: "Female"))

        let character = try await sut.getCharacter(2)

        #expect(character == Character(id: 2,
                                       name: "Birdperson",
                                       status: .dead,
                                       species: "Human",
                                       gender: .female,
                                       image: "url2"))
    }

    @Test func getCharacterReturnsNilWhenNotFound() async throws {
        dataSource.characterResult = .failure(NetworkError.notFound)
        let character = try await sut.getCharacter(99999)
        #expect(character == nil)
    }

    @Test func getCharacterPropagatesOtherErrors() async {
        dataSource.characterResult = .failure(NetworkError.statusCode(500))
        await #expect(throws: NetworkError.statusCode(500)) { _ = try await sut.getCharacter(1) }
    }

    // MARK: - Search cache

    private func stubSearchResult(_ names: String...) {
        dataSource.result = .success(ServerArray(
            info: ServerInformation(pages: 1),
            results: names.enumerated().map { serverCharacter(id: $0.offset + 1, name: $0.element) }
        ))
    }

    @Test func cacheTTLIsTwoMinutes() {
        #expect(CharacterRepository.searchCacheTTL == 120)
    }

    @Test func validCachedResultIsReturnedWithoutNetworkCall() async throws {
        stubSearchResult("Rick")
        let first = try await sut.getCharacters("rick")

        clock.advance(by: 119)
        let second = try await sut.getCharacters("rick")

        #expect(dataSource.getCharactersCallCount == 1)
        #expect(second == first)
    }

    @Test func expiredCacheFetchesFromNetworkAndUpdatesCache() async throws {
        stubSearchResult("Rick")
        _ = try await sut.getCharacters("rick")

        clock.advance(by: 120)
        stubSearchResult("Rick Sanchez")
        let refreshed = try await sut.getCharacters("rick")

        #expect(dataSource.getCharactersCallCount == 2)
        #expect(refreshed.map(\.name) == ["Rick Sanchez"])

        // The refreshed value is cached again, with a new expiration time.
        clock.advance(by: 60)
        let cached = try await sut.getCharacters("rick")
        #expect(dataSource.getCharactersCallCount == 2)
        #expect(cached.map(\.name) == ["Rick Sanchez"])
    }

    @Test func differentQueriesAreCachedIndependently() async throws {
        stubSearchResult("Rick")
        _ = try await sut.getCharacters("rick")
        stubSearchResult("Morty")
        let morty = try await sut.getCharacters("morty")

        #expect(dataSource.getCharactersCallCount == 2)
        #expect(morty.map(\.name) == ["Morty"])
    }

    @Test func queryIsNormalizedForCacheLookup() async throws {
        stubSearchResult("Rick")
        _ = try await sut.getCharacters("rick")
        _ = try await sut.getCharacters("  RICK ")

        #expect(dataSource.getCharactersCallCount == 1)
    }

    @Test func emptyResultsAreCached() async throws {
        dataSource.result = .failure(NetworkError.notFound)
        _ = try await sut.getCharacters("zzzz")
        let second = try await sut.getCharacters("zzzz")

        #expect(second.isEmpty)
        #expect(dataSource.getCharactersCallCount == 1)
    }

    @Test func failuresAreNotCached() async throws {
        dataSource.result = .failure(NetworkError.statusCode(500))
        await #expect(throws: NetworkError.statusCode(500)) { _ = try await sut.getCharacters("rick") }

        stubSearchResult("Rick")
        let characters = try await sut.getCharacters("rick")

        #expect(dataSource.getCharactersCallCount == 2)
        #expect(characters.map(\.name) == ["Rick"])
    }
}
