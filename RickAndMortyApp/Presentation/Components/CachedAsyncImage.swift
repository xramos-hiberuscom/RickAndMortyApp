//
//  CachedAsyncImage.swift
//  RickAndMortyApp
//
//  Created by Xavier Ramos Sole on 24/11/2026.
//

import SwiftUI

/// `AsyncImage` replacement that caches downloaded images (see `ImageLoader`).
struct CachedAsyncImage<Content: View, Placeholder: View>: View {

    private let url: URL?
    private let loader: ImageLoader
    private let content: (Image) -> Content
    private let placeholder: () -> Placeholder

    @State private var image: PlatformImage?

    init(url: URL?,
         loader: ImageLoader = .shared,
         @ViewBuilder content: @escaping (Image) -> Content,
         @ViewBuilder placeholder: @escaping () -> Placeholder) {
        self.url = url
        self.loader = loader
        self.content = content
        self.placeholder = placeholder
        // Cached images show immediately, without a placeholder flash when scrolling.
        _image = State(initialValue: url.flatMap { loader.cachedImage(for: $0) })
    }

    var body: some View {
        Group {
            if let image {
                content(Image(platformImage: image))
            } else {
                placeholder()
            }
        }
        .task(id: url) { await load() }
    }

    private func load() async {
        guard let url else { image = nil; return }
        if let cached = loader.cachedImage(for: url) { image = cached; return }

        image = nil
        // A failed or cancelled load keeps showing the placeholder.
        image = try? await loader.image(for: url)
    }
}

private extension Image {
    init(platformImage: PlatformImage) {
        #if canImport(UIKit)
        self.init(uiImage: platformImage)
        #else
        self.init(nsImage: platformImage)
        #endif
    }
}
