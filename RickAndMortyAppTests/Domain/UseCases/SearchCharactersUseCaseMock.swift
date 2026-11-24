//
//  SearchCharactersUseCaseMock.swift
//  RickAndMortyAppTests
//

import Foundation
@testable import RickAndMortyApp

/// Use case whose calls stay suspended until the test resolves them.
/// It deliberately ignores cancellation, simulating a request that still completes.
final class SearchCharactersUseCaseMock: SearchCharactersUseCaseContract {
    private(set) var requestedNames: [String] = []
    private var pending: [String: CheckedContinuation<[Character], Error>] = [:]

    func execute(name: String) async throws -> [Character] {
        requestedNames.append(name)
        return try await withCheckedThrowingContinuation { pending[name] = $0 }
    }

    func isPending(_ name: String) -> Bool { pending[name] != nil }

    func resolve(_ name: String, with result: Result<[Character], Error>) {
        pending.removeValue(forKey: name)?.resume(with: result)
    }
}
