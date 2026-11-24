//
//  NetworkManagerMock.swift
//  RickAndMortyAppTests
//
//  Created by Xavier Ramos Sole on 24/11/2026.
//

import Foundation
@testable import RickAndMortyApp

final class NetworkManagerMock: NetworkManagerContract {
    var receivedEndpoint: Endpoint?
    var result: Result<ServerArray<ServerCharacter>, NetworkError> = .success(
        ServerArray(info: ServerInformation(pages: 1), results: [])
    )

    func perform<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        receivedEndpoint = endpoint
        switch result {
        case .success(let value): return value as! T
        case .failure(let error): throw error
        }
    }
}
