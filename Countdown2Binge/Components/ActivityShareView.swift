//
//  ActivityShareView.swift
//  Countdown2Binge
//
//  The system share sheet, wrapped for SwiftUI.
//
//  Handing items to UIActivityViewController rather than implementing each
//  destination means Messages, Instagram, TikTok, Notes, AirDrop and anything
//  else the user has installed all work with no per-app code, no URL schemes to
//  declare, and nothing to keep up to date when those apps change.
//

import SwiftUI
import UIKit
import LinkPresentation
import UniformTypeIdentifiers

struct ActivityShareView: UIViewControllerRepresentable {
    /// Anything UIActivityViewController accepts: UIImage, String, URL.
    /// Order matters — most apps preview the first item they understand.
    let items: [Any]
    /// `completed` is false when the sheet was dismissed without picking
    /// anything, so the caller can leave its own sheet open instead of
    /// tearing down behind a user who just changed their mind.
    var onComplete: (_ completed: Bool, _ activity: UIActivity.ActivityType?) -> Void = { _, _ in }

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        controller.completionWithItemsHandler = { activity, completed, _, _ in
            onComplete(completed, activity)
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

/// Wraps a generated image so the share sheet has something to say about it.
///
/// A bare UIImage gives the header "PNG Image · 720 KB" and no caption. Feeding
/// LPLinkMetadata a title and a thumbnail makes the header show the show name
/// and the card, which is also what receiving apps use to preview it.
final class ShareCardSource: NSObject, UIActivityItemSource {
    private let image: UIImage
    private let title: String

    init(image: UIImage, title: String) {
        self.image = image
        self.title = title
    }

    func activityViewControllerPlaceholderItem(_ controller: UIActivityViewController) -> Any {
        image
    }

    func activityViewController(
        _ controller: UIActivityViewController,
        itemForActivityType activityType: UIActivity.ActivityType?
    ) -> Any? {
        image
    }

    func activityViewController(
        _ controller: UIActivityViewController,
        subjectForActivityType activityType: UIActivity.ActivityType?
    ) -> String {
        title
    }

    func activityViewControllerLinkMetadata(_ controller: UIActivityViewController) -> LPLinkMetadata? {
        let metadata = LPLinkMetadata()
        metadata.title = title
        // BOTH providers. With only imageProvider set the header renders blank
        // — the sheet asks for the icon first and gives up when there isn't
        // one. They can point at the same image.
        let preview = Self.provider(for: Self.thumbnail(image))
        metadata.imageProvider = preview
        metadata.iconProvider = Self.provider(for: Self.thumbnail(image))
        return metadata
    }

    /// Registers PNG data under an explicit type.
    ///
    /// `NSItemProvider(object: someUIImage)` can register under a *dynamic*
    /// type identifier that the share sheet doesn't recognise as an image, so
    /// it draws nothing. Declaring `.png` removes the guesswork.
    private static func provider(for image: UIImage) -> NSItemProvider {
        let provider = NSItemProvider()
        provider.registerDataRepresentation(for: .png, visibility: .all) { completion in
            completion(image.pngData(), nil)
            return nil
        }
        return provider
    }

    /// The card is 1080x1920. LinkPresentation has to resolve the preview
    /// before the sheet draws, and at full size it often doesn't finish in
    /// time — which is the other half of the blank header. The shared item
    /// stays full resolution; only the preview is downscaled.
    private static func thumbnail(_ image: UIImage, maxDimension: CGFloat = 512) -> UIImage {
        let longest = max(image.size.width, image.size.height)
        guard longest > maxDimension else { return image }

        let scale = maxDimension / longest
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        return UIGraphicsImageRenderer(size: size).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
