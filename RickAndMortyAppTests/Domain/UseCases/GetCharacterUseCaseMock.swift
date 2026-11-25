//
//  GetCharacterUseCaseMock.swift
//  RickAndMortyAppTests
//

import Foundation
@testable import RickAndMortyApp

final class GetCharacterUseCaseMock: GetCharacterUseCaseContract {
    private(set) var requestedIds: [Int] = []
    var result: Result<Character?, Error> = .success(nil)

    func execute(id: Int) async throws -> Character? {
        requestedIds.append(id)
        return try result.get()
    }
}
