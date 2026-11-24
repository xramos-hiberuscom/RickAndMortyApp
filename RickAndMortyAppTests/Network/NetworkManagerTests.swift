//
//  NetworkManagerTests.swift
//  RickAndMortyAppTests
//

import Foundation
import Testing
@testable import RickAndMortyApp

private final class StubURLProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var handler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func stopLoading() {}

    override func startLoading() {
        do {
            let (response, data) = try StubURLProtocol.handler!(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }
}

private struct Sample: Decodable, Equatable { let originName: String }

@Suite(.serialized)
struct NetworkManagerTests {

    private func makeSUT(status: Int = 200, body: String = "{}", error: URLError? = nil) -> NetworkManager {
        StubURLProtocol.handler = { request in
            if let error { throw error }
            let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!
            return (response, Data(body.utf8))
        }
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubURLProtocol.self]
        return NetworkManager(session: URLSession(configuration: config))
    }

    private let request = Endpoint(path: "/character")

    @Test func decodesSnakeCaseOnSuccess() async throws {
        let sut = makeSUT(body: #"{"origin_name":"Earth"}"#)
        let result: Sample = try await sut.perform(request)
        #expect(result == Sample(originName: "Earth"))
    }

    @Test func mapsNotFound() async {
        let sut = makeSUT(status: 404, body: #"{"error":"There is nothing here"}"#)
        await #expect(throws: NetworkError.notFound) { let _: Sample = try await sut.perform(request) }
    }

    @Test func mapsServerError() async {
        let sut = makeSUT(status: 500)
        await #expect(throws: NetworkError.statusCode(500)) { let _: Sample = try await sut.perform(request) }
    }

    @Test func mapsTransportError() async {
        let sut = makeSUT(error: URLError(.notConnectedToInternet))
        await #expect(throws: NetworkError.transport(.notConnectedToInternet)) { let _: Sample = try await sut.perform(request) }
    }

    @Test func mapsDecodingError() async {
        let sut = makeSUT(body: "{}")
        do {
            let _: Sample = try await sut.perform(request)
            Issue.record("Expected decoding error")
        } catch let error as NetworkError {
            if case .decoding = error {} else { Issue.record("Wrong error: \(error)") }
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test func buildsCharacterSearchURL() throws {
        let url = try Endpoint.characters(name: "rick", page: 2).urlRequest().url?.absoluteString
        #expect(url == "https://rickandmortyapi.com/api/character?name=rick&page=2")
        #expect(try Endpoint.character(id: 1).urlRequest().url?.absoluteString == "https://rickandmortyapi.com/api/character/1")
    }
}
