//
//  CachedAsyncImage.swift
//  Countdown2Binge
//

import SwiftUI
import UIKit

// MARK: - Demo Mode Provider
enum DemoModeProvider {
    /// Extract demo image name from a URL string (e.g., "demo://severance" -> "severance")
    static func demoImageName(from urlString: String?) -> String? {
        guard let urlString = urlString, urlString.hasPrefix("demo://") else { return nil }
        return String(urlString.dropFirst(7))
    }
}

/// A more resilient async image loader that handles lazy containers (LazyVStack/LazyVGrid) properly.
/// Uses .task(id:) which automatically cancels/restarts when the URL changes or view reappears.
struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: URL?
    let content: (Image) -> Content
    let placeholder: () -> Placeholder

    /// Check for demo image from asset catalog
    private var demoImage: UIImage? {
        guard let imageName = DemoModeProvider.demoImageName(from: url?.absoluteString) else { return nil }
        return UIImage(named: imageName)
    }

    // Check cache immediately during view evaluation (synchronous)
    private var cachedImage: UIImage? {
        guard let url = url else { return nil }
        return ImageCache.shared.get(for: url)
    }

    /// The loaded image, but only if it belongs to the url currently being
    /// rendered — otherwise a recycled view would show the previous show's
    /// artwork for the frame before `.task(id:)` gets a chance to clear it.
    private var imageMatchingCurrentURL: UIImage? {
        guard let url, loadedURL == url else { return nil }
        return loadedImage
    }

    @State private var loadedImage: UIImage?
    /// Which url `loadedImage` belongs to. @State survives this view being
    /// recycled onto a different url, so the image is only ever trusted when
    /// it provably matches the url being asked for right now.
    @State private var loadedURL: URL?

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
            } else if let image = cachedImage ?? imageMatchingCurrentURL {
                content(Image(uiImage: image))
            } else {
                placeholder()
            }
        }
        // .task(id:) is the key fix - it automatically:
        // 1. Cancels when view disappears (LazyVGrid recycles)
        // 2. Restarts when view reappears with same URL
        // 3. Cancels and restarts if URL changes
        .task(id: url) {
            await loadImage()
        }
    }

    private func loadImage() async {
        guard let url = url else {
            loadedImage = nil
            loadedURL = nil
            return
        }

        // Don't fetch demo images from network
        if url.absoluteString.hasPrefix("demo://") { return }

        // SwiftUI recycles this view onto a different url (a card stack reusing
        // its slots, a grid cell scrolling). `loadedImage` is @State and
        // survives that, so it still holds the PREVIOUS url's image — drop it
        // before it can be rendered against the new one. Without this the view
        // shows one show's artwork over another's.
        loadedImage = nil
        loadedURL = nil

        // Check cache first (might have been loaded by another view)
        if let cached = ImageCache.shared.get(for: url) {
            self.loadedImage = cached
            self.loadedURL = url
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)

            // Check for task cancellation
            try Task.checkCancellation()

            if let uiImage = UIImage(data: data) {
                ImageCache.shared.set(uiImage, for: url)
                self.loadedImage = uiImage
                self.loadedURL = url
            }
        } catch is CancellationError {
            // Task was cancelled (view scrolled away) - this is normal, don't log
        } catch {
            // Network error - image stays as placeholder
        }
    }
}

/// Simple in-memory image cache
final class ImageCache {
    static let shared = ImageCache()

    private var cache = NSCache<NSURL, UIImage>()

    private init() {
        // Increased from 100 to handle scrolling through large lists
        cache.countLimit = 500
        // Also set a memory limit (~50MB for poster images)
        cache.totalCostLimit = 50 * 1024 * 1024
    }

    func get(for url: URL) -> UIImage? {
        cache.object(forKey: url as NSURL)
    }

    func set(_ image: UIImage, for url: URL) {
        // Store with cost based on image size for smarter eviction
        let cost = image.jpegData(compressionQuality: 1.0)?.count ?? 0
        cache.setObject(image, forKey: url as NSURL, cost: cost)
    }
}
