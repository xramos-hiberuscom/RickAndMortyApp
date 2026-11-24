//
//  ImageLoader.swift
//  RickAndMortyApp
//
//  Created by Xavier Ramos Sole on 24/11/2026.
//

import Foundation

#if canImport(UIKit)
import UIKit
typealias PlatformImage = UIImage
#elseif canImport(AppKit)
import AppKit
typealias PlatformImage = NSImage
#endif

/// Downloads images and caches them in memory (`NSCache`) and on disk (`URLCache`).
final class ImageLoader {

    static let shared = ImageLoader()

    // MARK: - Variables

    private let session: URLSession
    private let memoryCache = NSCache<NSURL, PlatformImage>()

    // MARK: - Methods

    init(session: URLSession = ImageLoader.makeSession()) {
        self.session = session
    }

    /// Image already available in memory, if any.
    func cachedImage(for url: URL) -> PlatformImage? {
        memoryCache.object(forKey: url as NSURL)
    }

    func image(for url: URL) async throws -> PlatformImage {
        if let cached = cachedImage(for: url) { return cached }

        let (data, response) = try await session.data(from: url)

        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode),
              let image = PlatformImage(data: data) else {
            throw URLError(.cannotDecodeContentData)
        }

        memoryCache.setObject(image, forKey: url as NSURL)
        return image
    }

    /// Session with a persistent disk cache, so images survive app launches.
    static func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = URLCache(memoryCapacity: 20 * 1024 * 1024,
                                          diskCapacity: 100 * 1024 * 1024)
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        return URLSession(configuration: configuration)
    }
}
