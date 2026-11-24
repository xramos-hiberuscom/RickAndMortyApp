//
//  CharacterRemoteDataSourceMock.swift
//  RickAndMortyAppTests
//

import Foundation
@testable import RickAndMortyApp

final class CharacterRemoteDataSourceMock: CharacterRemoteDataSourceContract {
    var receivedName: String?
    var result: Result<ServerArray<ServerCharacter>, Error> = .success(
        ServerArray(info: ServerInformation(pages: 1), results: [])
    )

    func getCharacters(_ name: String) async throws -> ServerArray<ServerCharacter> {
        receivedName = name
        return try result.get()
    }
}
