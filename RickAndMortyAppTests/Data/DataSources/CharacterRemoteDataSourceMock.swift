//
//  CharacterRemoteDataSourceMock.swift
//  RickAndMortyAppTests
//

import Foundation
@testable import RickAndMortyApp

final class CharacterRemoteDataSourceMock: CharacterRemoteDataSourceContract {
    var receivedName: String?
    private(set) var receivedPages: [Int] = []
    private(set) var getCharactersCallCount = 0
    var result: Result<ServerArray<ServerCharacter>, Error> = .success(
        ServerArray(info: ServerInformation(pages: 1), results: [])
    )

    var receivedId: Int?
    var characterResult: Result<ServerCharacter, Error> = .failure(NetworkError.notFound)

    func getCharacter(_ id: Int) async throws -> ServerCharacter {
        receivedId = id
        return try characterResult.get()
    }

    func getCharacters(_ name: String, page: Int) async throws -> ServerArray<ServerCharacter> {
        receivedName = name
        receivedPages.append(page)
        getCharactersCallCount += 1
        return try result.get()
    }
}
