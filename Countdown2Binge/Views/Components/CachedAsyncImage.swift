//
//  CachedAsyncImage.swift
//  Countdown2Binge
//

import SwiftUI
import UIKit

/// A more resilient async image loader that handles rapid view updates better than AsyncImage
struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: URL?
    let content: (Image) -> Content
    let placeholder: () -> Placeholder

    /// Check for demo image from asset catalog
    private var demoImage: UIImage? {
        guard let imageName = DemoModeProvider.demoImageName(from: url?.absoluteString) else { return nil }
        return UIImage(named: imageName)
    }

    // Check cache immediately during view init
    private var cachedImage: UIImage? {
        guard let url = url else { return nil }
        return ImageCache.shared.get(for: url)
    }

    @State private var loadedImage: UIImage?
    @State private var isLoading = false

    init(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
    }

    var body: some View {
        Group {
            // Demo images take priority
            if let image = demoImage {
                content(Image(uiImage: image))
            } else if let image = cachedImage ?? loadedImage {
                content(Image(uiImage: image))
            } else {
                placeholder()
            }
        }
        .onAppear {
            if demoImage == nil && cachedImage == nil && loadedImage == nil {
                loadImage()
            }
        }
        .onChange(of: url) { _, newURL in
            if newURL != nil && demoImage == nil && cachedImage == nil && loadedImage == nil {
                loadImage()
            }
        }
    }

    private func loadImage() {
        guard let url = url, !isLoading else { return }

        // Don't fetch demo images from network
        if url.absoluteString.hasPrefix("demo://") { return }

        // Double-check cache
        if let cached = ImageCache.shared.get(for: url) {
            self.loadedImage = cached
            return
        }

        isLoading = true

        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let uiImage = UIImage(data: data) {
                    ImageCache.shared.set(uiImage, for: url)
                    await MainActor.run {
                        self.loadedImage = uiImage
                        self.isLoading = false
                    }
                } else {
                    await MainActor.run {
                        self.isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
}

/// Simple in-memory image cache
final class ImageCache {
    static let shared = ImageCache()

    private var cache = NSCache<NSURL, UIImage>()

    private init() {
        cache.countLimit = 100
    }

    func get(for url: URL) -> UIImage? {
        cache.object(forKey: url as NSURL)
    }

    func set(_ image: UIImage, for url: URL) {
        cache.setObject(image, forKey: url as NSURL)
    }
}
