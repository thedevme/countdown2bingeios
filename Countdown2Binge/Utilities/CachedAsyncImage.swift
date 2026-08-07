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

    @State private var loadedImage: UIImage?

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
        // .task(id:) is the key fix - it automatically:
        // 1. Cancels when view disappears (LazyVGrid recycles)
        // 2. Restarts when view reappears with same URL
        // 3. Cancels and restarts if URL changes
        .task(id: url) {
            await loadImage()
        }
    }

    private func loadImage() async {
        guard let url = url else { return }

        // Don't fetch demo images from network
        if url.absoluteString.hasPrefix("demo://") { return }

        // Check cache first (might have been loaded by another view)
        if let cached = ImageCache.shared.get(for: url) {
            self.loadedImage = cached
            return
        }

        // Already have this image loaded
        if loadedImage != nil { return }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)

            // Check for task cancellation
            try Task.checkCancellation()

            if let uiImage = UIImage(data: data) {
                ImageCache.shared.set(uiImage, for: url)
                self.loadedImage = uiImage
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
