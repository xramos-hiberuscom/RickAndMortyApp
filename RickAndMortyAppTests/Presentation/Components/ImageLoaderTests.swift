//
//  ImageLoaderTests.swift
//  RickAndMortyAppTests
//

import Foundation
import Testing
@testable import RickAndMortyApp

private final class ImageStubURLProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var requestCount = 0
    nonisolated(unsafe) static var status = 200
    nonisolated(unsafe) static var body = Data()

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func stopLoading() {}

    override func startLoading() {
        Self.requestCount += 1
        let response = HTTPURLResponse(url: request.url!, statusCode: Self.status, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Self.body)
        client?.urlProtocolDidFinishLoading(self)
    }
}

@Suite(.serialized)
@MainActor
struct ImageLoaderTests {

    // 1x1 transparent PNG
    private nonisolated static let png = Data(base64Encoded:
        "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==")!
    private let url = URL(string: "https://example.com/1.jpeg")!

    private func makeSUT(status: Int = 200, body: Data = png) -> ImageLoader {
        ImageStubURLProtocol.requestCount = 0
        ImageStubURLProtocol.status = status
        ImageStubURLProtocol.body = body
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [ImageStubURLProtocol.self]
        return ImageLoader(session: URLSession(configuration: config))
    }

    @Test func downloadsImageOnFirstRequest() async throws {
        let sut = makeSUT()
        _ = try await sut.image(for: url)
        #expect(ImageStubURLProtocol.requestCount == 1)
    }

    @Test func secondRequestIsServedFromCache() async throws {
        let sut = makeSUT()
        _ = try await sut.image(for: url)
        _ = try await sut.image(for: url)

        #expect(ImageStubURLProtocol.requestCount == 1)
        #expect(sut.cachedImage(for: url) != nil)
    }

    @Test func differentURLsAreCachedIndependently() async throws {
        let sut = makeSUT()
        _ = try await sut.image(for: url)
        _ = try await sut.image(for: URL(string: "https://example.com/2.jpeg")!)
        #expect(ImageStubURLProtocol.requestCount == 2)
    }

    @Test func failedResponseIsNotCached() async {
        let sut = makeSUT(status: 500)
        await #expect(throws: URLError.self) { _ = try await sut.image(for: url) }
        #expect(sut.cachedImage(for: url) == nil)
    }

    @Test func invalidImageDataIsNotCached() async {
        let sut = makeSUT(body: Data("not an image".utf8))
        await #expect(throws: URLError.self) { _ = try await sut.image(for: url) }
        #expect(sut.cachedImage(for: url) == nil)
    }
}
