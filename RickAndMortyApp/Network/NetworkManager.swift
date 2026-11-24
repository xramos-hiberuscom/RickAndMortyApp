//
//  NetworkManager.swift
//  RickAndMortyApp
//
//  Created by Xavier Ramos Sole on 24/11/2026.
//

import Foundation

protocol NetworkManagerContract {
    func perform<T: Decodable>(_ endpoint: Endpoint) async throws -> T
}

final class NetworkManager: NetworkManagerContract {

    // MARK: - Variables

    private let session: URLSession
    private let decoder: JSONDecoder

    // MARK: - Methods

    init(session: URLSession = .shared) {
        self.session = session

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder = decoder
    }

    func perform<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        let data: Data
        let response: URLResponse

        do {
            let request = try endpoint.urlRequest()
            (data, response) = try await session.data(for: request)
        } catch let error as URLError {
            throw NetworkError.transport(error.code)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200..<300:
            break
        case 404:
            // The API answers 404 when a search has no results.
            throw NetworkError.notFound
        default:
            throw NetworkError.statusCode(httpResponse.statusCode)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decoding(String(describing: error))
        }
    }
}
