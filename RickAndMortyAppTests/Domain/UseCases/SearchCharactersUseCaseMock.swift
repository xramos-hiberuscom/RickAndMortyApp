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
    private(set) var requestedPages: [Int] = []
    private var pending: [String: CheckedContinuation<CharactersPage, Error>] = [:]

    private func key(_ name: String, _ page: Int) -> String { "\(name)#\(page)" }

    func execute(name: String, page: Int) async throws -> CharactersPage {
        requestedNames.append(name)
        requestedPages.append(page)
        return try await withCheckedThrowingContinuation { pending[key(name, page)] = $0 }
    }

    func isPending(_ name: String, page: Int = 1) -> Bool { pending[key(name, page)] != nil }

    /// Resolves the pending call for `name` and `page`. `hasNextPage` tells whether more pages follow.
    func resolve(_ name: String, page: Int = 1, hasNextPage: Bool = false, with result: Result<[Character], Error>) {
        pending.removeValue(forKey: key(name, page))?.resume(with: result.map {
            CharactersPage(characters: $0, page: page, hasNextPage: hasNextPage)
        })
    }
}
