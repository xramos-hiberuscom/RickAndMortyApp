//
//  NetworkError.swift
//  RickAndMortyApp
//
//  Created by Xavier Ramos Sole on 24/11/2026.
//

import Foundation

enum NetworkError: LocalizedError, Equatable {
    case invalidURL
    case transport(URLError.Code)
    case invalidResponse
    case notFound
    case statusCode(Int)
    case decoding(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The request URL is not valid."
        case .transport(let code):
            return code == .notConnectedToInternet
                ? "No internet connection."
                : "Network error (\(code.rawValue))."
        case .invalidResponse:
            return "The server response was not valid."
        case .notFound:
            return "Nothing was found."
        case .statusCode(let code):
            return "The server responded with status \(code)."
        case .decoding:
            return "The server data could not be read."
        }
    }
}
