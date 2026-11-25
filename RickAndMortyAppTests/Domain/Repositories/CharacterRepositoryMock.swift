//
//  CharacterRepositoryMock.swift
//  RickAndMortyAppTests
//

import Foundation
@testable import RickAndMortyApp

/// Repository whose calls stay suspended until the test resolves them.
/// It deliberately ignores cancellation, simulating a request that still completes.
final class CharacterRepositoryMock: CharacterRepositoryContract {
    private(set) var requestedNames: [String] = []
    private var pending: [String: CheckedContinuation<[Character], Error>] = [:]

    func getCharacters(_ name: String) async throws -> [Character] {
        requestedNames.append(name)
        return try await withCheckedThrowingContinuation { pending[name] = $0 }
    }

    private(set) var requestedId: Int?
    var characterResult: Result<Character?, Error> = .success(nil)

    func getCharacter(_ id: Int) async throws -> Character? {
        requestedId = id
        return try characterResult.get()
    }

    func isPending(_ name: String) -> Bool { pending[name] != nil }

    func resolve(_ name: String, with result: Result<[Character], Error>) {
        pending.removeValue(forKey: name)?.resume(with: result)
    }
}
