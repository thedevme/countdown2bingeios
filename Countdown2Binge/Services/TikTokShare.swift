//
//  TikTokShare.swift
//  Countdown2Binge
//
//  Share Kit — opens TikTok's editor with the card already loaded, instead of
//  dropping the user on TikTok's home screen to find it themselves.
//
//  Share Kit does not take an image in memory. It takes PHAsset local
//  identifiers, so the card still gets written to the photo library first; the
//  SDK just hands TikTok the asset id. That is why `saveToPhotos` returns the
//  identifier rather than a Bool.
//
//  Everything here is gated on `TikTokConfig.isConfigured`. Until the client
//  key and redirect URI exist, `share` returns nil and the caller falls back to
//  simply opening TikTok — so this file is inert rather than broken.
//

import UIKit
import TikTokOpenShareSDK

/// The two values that come from TikTok's Developer Portal.
///
/// - `clientKey`: Developer Portal → your app → App details.
/// - `redirectURI`: must be a **universal link** you control, registered on the
///   Portal. That also means adding an Associated Domains entitlement
///   (`applinks:yourdomain.com`) and hosting an apple-app-site-association
///   file — the app currently has no Associated Domains entitlement.
/// - `callerURLScheme`: TikTok expects your client key registered as a URL
///   scheme in CFBundleURLTypes so it can call back.
enum TikTokConfig {
    static let clientKey: String? = "awaamb61lpsdlx76"

    /// A custom scheme, not a universal link.
    ///
    /// TikTok's guide recommends a universal link, but the SDK does not require
    /// one: `TikTokShareResponse` only prefix-matches this string against the
    /// callback URL, and the service just does `URL(string:)`. A custom scheme
    /// therefore works and comes straight back into the app through
    /// `onOpenURL` — a universal link would need an Associated Domains
    /// entitlement and a hosted apple-app-site-association file, and without
    /// those the callback would open Safari instead of returning here.
    ///
    /// This exact string must also be registered on the Developer Portal.
    static let redirectURI: String? = "awaamb61lpsdlx76://tiktok-share"

    /// Registered in CFBundleURLTypes. TikTok's guide uses the client key.
    static var callerURLScheme: String? { clientKey }

    static var isConfigured: Bool {
        clientKey?.isEmpty == false && redirectURI?.isEmpty == false
    }
}

enum TikTokShare {
    static var isConfigured: Bool { TikTokConfig.isConfigured }

    /// Hand TikTok a saved asset. Returns the response state, or nil when the
    /// SDK isn't configured or refused the request outright.
    ///
    /// Note the SDK's own constraint on the card: aspect ratio must fall
    /// between 1/2.2 and 2.2. The portrait card is 9:16 (0.5625), inside that.
    @MainActor
    static func share(localIdentifier: String) async -> TikTokShareResponseState? {
        guard let clientKey = TikTokConfig.clientKey,
              let redirectURI = TikTokConfig.redirectURI,
              let callerScheme = TikTokConfig.callerURLScheme else { return nil }

        let request = TikTokShareRequest(
            localIdentifiers: [localIdentifier],
            mediaType: .image,
            redirectURI: redirectURI
        )
        request.customConfig = TikTokShareRequest.CustomConfiguration(
            clientKey: clientKey,
            callerUrlScheme: callerScheme
        )

        return await withCheckedContinuation { continuation in
            var resumed = false
            let sent = request.send { response in
                guard !resumed else { return }
                resumed = true
                continuation.resume(returning: (response as? TikTokShareResponse)?.shareState)
            }
            // `send` returns false without ever calling the completion when the
            // request is invalid, which would otherwise leak the continuation.
            if !sent, !resumed {
                resumed = true
                continuation.resume(returning: nil)
            }
        }
    }
}
