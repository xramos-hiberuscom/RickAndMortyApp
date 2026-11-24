//
//  Endpoint.swift
//  RickAndMortyApp
//
//  Created by Xavier Ramos Sole on 24/11/2026.
//

import Foundation

/// Describes a request to the Rick and Morty API and builds its `URLRequest`.
struct Endpoint {
    static let defaultBaseURL = "https://rickandmortyapi.com/api"

    var path: String
    var queryItems: [URLQueryItem] = []
    var baseURL: String = Endpoint.defaultBaseURL

    func urlRequest() throws -> URLRequest {
        guard var components = URLComponents(string: baseURL) else {
            throw NetworkError.invalidURL
        }
        components.path += path.hasPrefix("/") ? path : "/" + path
        components.queryItems = queryItems.isEmpty ? nil : queryItems

        guard let url = components.url else { throw NetworkError.invalidURL }
        return URLRequest(url: url)
    }

    // MARK: - Endpoints

    static func characters(name: String? = nil, page: Int? = nil) -> Endpoint {
        var items: [URLQueryItem] = []
        if let name, !name.isEmpty { items.append(URLQueryItem(name: "name", value: name)) }
        if let page { items.append(URLQueryItem(name: "page", value: String(page))) }
        return Endpoint(path: "/character", queryItems: items)
    }

    static func character(id: Int) -> Endpoint {
        Endpoint(path: "/character/\(id)")
    }
}
