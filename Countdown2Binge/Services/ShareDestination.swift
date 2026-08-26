//
//  ShareDestination.swift
//  Countdown2Binge
//
//  Where a binge card can go, and how each one is reached.
//
//  Only Messages has an API that accepts an image and body text directly
//  (MFMessageComposeViewController). The social apps have no such API, so the
//  route for all of them is the same: save the card to the user's photo
//  library, put the post text on the clipboard, then open the app. The user
//  attaches the card from their camera roll and pastes the caption.
//
//  Instagram is the one exception that can skip the camera roll — its Stories
//  URL scheme reads the image straight off the pasteboard — so it gets a
//  direct hand-off with a save-and-open fallback.
//

import UIKit
import Photos

enum ShareDestination: String, CaseIterable, Identifiable {
    case messages
    case instagram
    case tiktok
    case x

    var id: String { rawValue }

    var label: String {
        switch self {
        case .messages:  return String(localized: "share_messages")
        case .instagram: return String(localized: "share_instagram")
        case .tiktok:    return String(localized: "share_tiktok")
        case .x:         return String(localized: "share_x")
        }
    }

    /// What sits inside the tile.
    ///
    /// Messages keeps an SF Symbol — it's Apple's own, and the envelope glyph
    /// reads instantly. The three third-party destinations use plain text
    /// instead of a logo: no trademark artwork ships in the bundle, so there is
    /// nothing to keep in step with anyone's brand guidelines, and nothing for
    /// review to question under 5.2.1. The label underneath spells out the full
    /// name, so the short mark never has to carry recognition on its own.
    enum Mark {
        case symbol(String)
        case text(String)
    }

    var mark: Mark {
        switch self {
        case .messages:  return .symbol("message.fill")
        case .instagram: return .text("I")
        case .tiktok:    return .text("T")
        case .x:         return .text("X")
        }
    }

    var tint: UIColor {
        switch self {
        case .messages:  return UIColor(red: 0.20, green: 0.78, blue: 0.35, alpha: 1)
        case .instagram: return UIColor(red: 0.88, green: 0.19, blue: 0.42, alpha: 1)
        case .tiktok:    return UIColor(red: 0.11, green: 0.11, blue: 0.13, alpha: 1)
        case .x:         return UIColor(red: 0.11, green: 0.11, blue: 0.13, alpha: 1)
        }
    }

    /// Messages shows the card inline in a bubble, which suits a wide card.
    /// Everything else is a feed or a story, which is vertical.
    var wantsPortraitCard: Bool {
        self != .messages
    }

    /// Handled in-app by a compose controller rather than by leaving.
    var isInAppCompose: Bool {
        self == .messages
    }

    /// Whether the confirmation panel offers a Copy button for the caption
    /// instead of a button that opens the destination app.
    ///
    /// X and TikTok. Both say plainly that the card is in the library — the
    /// save is silent otherwise, and a user who isn't told will assume nothing
    /// happened — then hand over the caption to copy.
    ///
    /// TikTok is here rather than on Share Kit because the Developer Portal
    /// hasn't verified the domain yet. `TikTokShare` stays wired and inert; the
    /// moment verification clears, drop `.tiktok` from this and Share Kit takes
    /// over again.
    var showsCopyButton: Bool {
        self == .x || self == .tiktok
    }

    // MARK: - Opening the app

    /// Scheme tried first, then the web fallback.
    ///
    /// X is the only one that can carry the caption in the URL — `?message=`
    /// lands it in the composer. Opening bare `twitter://post` is what left the
    /// composer empty. Neither app can be handed the image this way; that is
    /// what the camera roll is for.
    private func appURL(caption: String) -> URL? {
        let encoded = caption.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""
        switch self {
        case .messages:  return nil
        case .instagram: return URL(string: "instagram://app")
        case .tiktok:    return URL(string: "snssdk1233://")
        case .x:         return URL(string: "twitter://post?message=\(encoded)")
        }
    }

    private func webURL(caption: String) -> URL? {
        let encoded = caption.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""
        switch self {
        case .messages:  return nil
        case .instagram: return URL(string: "https://instagram.com")
        case .tiktok:    return URL(string: "https://www.tiktok.com/upload")
        // Documented to sometimes land on a login page inside the in-app
        // browser, which is why the scheme above is tried first.
        case .x:         return URL(string: "https://x.com/intent/post?text=\(encoded)")
        }
    }

    /// What the hand-off button opens.
    var openTargetLabel: String { label }

    /// Label on the hand-off button.
    ///
    /// Always "Open X" — the save has already happened by the time this is on
    /// screen, so a "Save to Photos" label would sit directly under a "Saved to
    /// Photos" confirmation and do something else entirely.
    var handoffButtonTitle: String {
        String(localized: "share_open_app \(openTargetLabel)")
    }

    var isInstalled: Bool {
        guard let url = appURL(caption: "") else { return true }
        return UIApplication.shared.canOpenURL(url)
    }

    // MARK: - Routing

    enum Outcome {
        case opened
        /// Card written to Photos. Carries the PHAsset local identifier, which
        /// TikTok's Share Kit needs to hand the asset to the editor.
        case saved(localIdentifier: String)
        case needsPhotoPermission
        case failed
    }

    /// Put the card in the user's library and the caption on the clipboard.
    /// Deliberately does NOT open the destination app — the caller shows the
    /// user what was saved first, so the hand-off isn't a blind jump out of the
    /// app with nothing visibly having happened.
    @MainActor
    func stage(card: UIImage, caption: String) async -> Outcome {
        // X is the exception: its panel has a Copy button, so pre-copying here
        // would make that button a no-op.
        if !showsCopyButton {
            UIPasteboard.general.string = caption
        }

        // Instagram Stories takes the image off the pasteboard directly, so it
        // can skip Photos entirely when it's installed.
        if self == .instagram, let handed = await openInstagramStories(card: card), handed {
            return .opened
        }

        guard let identifier = await Self.saveToPhotos(card) else {
            return .needsPhotoPermission
        }
        return .saved(localIdentifier: identifier)
    }

    /// Leave for the destination app. Called only after the save is confirmed.
    @MainActor
    func open(caption: String) async -> Bool {
        if let url = appURL(caption: caption), UIApplication.shared.canOpenURL(url) {
            return await UIApplication.shared.open(url)
        }
        if let url = webURL(caption: caption) {
            return await UIApplication.shared.open(url)
        }
        return false
    }

    /// `instagram-stories://share` reads a background image off the pasteboard.
    /// Returns nil when Instagram isn't installed so the caller falls through.
    @MainActor
    private func openInstagramStories(card: UIImage) async -> Bool? {
        guard let url = URL(string: "instagram-stories://share?source_application=\(Bundle.main.bundleIdentifier ?? "")"),
              UIApplication.shared.canOpenURL(url),
              let data = card.pngData() else { return nil }

        // Instagram reads this within a short window of the URL opening.
        UIPasteboard.general.setItems(
            [["com.instagram.sharedSticker.backgroundImage": data]],
            options: [.expirationDate: Date().addingTimeInterval(60 * 5)]
        )
        return await UIApplication.shared.open(url)
    }

    // MARK: - Photos

    /// Add-only access: we write one image and never read the library.
    /// Returns the new asset's local identifier, or nil if it wasn't saved.
    @MainActor
    static func saveToPhotos(_ image: UIImage) async -> String? {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else { return nil }

        var identifier: String?
        let saved = await withCheckedContinuation { continuation in
            PHPhotoLibrary.shared().performChanges {
                let request = PHAssetChangeRequest.creationRequestForAsset(from: image)
                identifier = request.placeholderForCreatedAsset?.localIdentifier
            } completionHandler: { success, _ in
                continuation.resume(returning: success)
            }
        }
        return saved ? identifier : nil
    }
}
