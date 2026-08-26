//
//  ShareSheet.swift
//  Countdown2Binge
//
//  Compose a binge card, then hand it to the system share sheet.
//
//  Two payloads, deliberately split:
//    • the card, as an image — title + season on the left, the app logo top
//      right, the stat right-aligned and floated to the right edge.
//    • the post text, as a string — the same title/season line, the status, and
//      the campaign hashtag, for wherever the user is posting.
//
//  The post text is generated, not typed. It has to survive being pasted into
//  Instagram or TikTok with no card visible, so it restates what the card says.
//
//  The backdrop is fetched to a UIImage before rendering: ImageRenderer draws
//  one frame synchronously and will not wait for an async image to load, so a
//  card built from LazyImage exports with an empty poster area.
//

import SwiftUI
import UIKit

struct ShareSheet: View {
    let show: ShowData
    let onClose: () -> Void

    /// Campaign tag appended to every post. Not localized — a hashtag is a
    /// single global handle, and translating it would fragment the feed.
    static let hashtag = "#CountdownToBingeApp"

    @State private var variant: ShareVariant = .countingDown
    @State private var isPresented = false
    /// Artwork resolved to concrete images so the card can be rendered.
    /// Landscape uses the backdrop; portrait uses the poster, whose 2:3 crop
    /// survives a 9:16 frame far better than a 16:9 backdrop does.
    @State private var backdropImage: UIImage?
    @State private var posterImage: UIImage?
    @State private var messagePayload: MessagePayload?
    @State private var statusNote: String?
    @State private var busyDestination: ShareDestination?
    /// Set once the card is in Photos. Holds the sheet open on a confirmation
    /// step so the user sees what was saved before leaving for the other app.
    @State private var handoff: Handoff?
    /// Whether the caption has been copied from the saved-panel.
    @State private var didCopyCaption = false
    @State private var shareItems: [Any] = []
    @State private var isSharing = false
    @State private var isPreparing = false
    @State private var didCopy = false

    enum ShareVariant {
        case countingDown
        case justBinged
    }

    /// Identifiable so the Messages composer can be driven by `.sheet(item:)`.
    struct MessagePayload: Identifiable {
        let id = UUID()
        let image: UIImage
        let body: String
    }

    /// A saved card waiting for the user to send it on.
    struct Handoff {
        let destination: ShareDestination
        let card: UIImage
    }

    private var seasonNumber: String {
        "\(show.currentSeason?.seasonNumber ?? show.numberOfSeasons)"
    }

    private var daysUntilBinge: Int? {
        show.daysUntilFinale ?? show.daysUntilPremiere
    }

    private var episodeCount: Int {
        show.currentSeason?.episodeCount ?? 0
    }

    /// "Just binged" needs the season to be over. Date-complete only — whether
    /// the user has actually watched it is the other axis and irrelevant here;
    /// an airing or pending season simply cannot be finished yet.
    private var canClaimBinged: Bool {
        show.showState == .bingeReady
    }

    // MARK: - Card copy

    /// The big number. "7/7" when finished, otherwise the countdown.
    private var statBig: String {
        if variant == .justBinged {
            return "\(episodeCount)/\(episodeCount)"
        }
        if let days = daysUntilBinge {
            return "\(days)"
        }
        return show.showState == .bingeReady
            ? String(localized: "share_stat_now")
            : String(localized: "share_stat_tbd")
    }

    private var statLabel: String {
        if variant == .justBinged {
            return String(localized: "share_season_complete")
        }
        if daysUntilBinge != nil {
            return String(localized: "share_days_to_binge")
        }
        return show.showState == .bingeReady
            ? String(localized: "status_ready_to_binge")
            : String(localized: "share_release_pending")
    }

    // MARK: - Post copy

    /// "Echo 7 — Season 2" — the same line the card carries, kept identical so a
    /// post with both reads as one thing.
    private var titleLine: String {
        "\(show.name) — \(String(localized: "share_post_season \(seasonNumber)"))"
    }

    private var statusLines: [String] {
        if variant == .justBinged {
            return [
                String(localized: "share_post_complete"),
                String(localized: "share_post_just_binged")
            ]
        }
        if let days = daysUntilBinge {
            return [
                String(localized: "share_post_days \(days)"),
                String(localized: "share_post_waiting")
            ]
        }
        if show.showState == .bingeReady {
            return [
                String(localized: "share_post_ready"),
                String(localized: "share_post_waiting")
            ]
        }
        return [
            String(localized: "share_post_pending"),
            String(localized: "share_post_waiting")
        ]
    }

    private var postText: String {
        (([titleLine] + statusLines) + ["", Self.hashtag]).joined(separator: "\n")
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Backdrop - fades in separately
            Color.black.opacity(isPresented ? 0.72 : 0)
                .ignoresSafeArea()
                .animation(.easeOut(duration: 0.2), value: isPresented)
                .onTapGesture { dismissSheet() }

            VStack {
                Spacer()

                if isPresented {
                    VStack(spacing: 0) {
                        // Drag handle
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 40, height: 4)
                            .padding(.top, 8)
                            .padding(.bottom, 12)

                        // Variant toggle
                        HStack(spacing: 4) {
                            VariantButton(
                                title: String(localized: "share_counting_down"),
                                isSelected: variant == .countingDown,
                                action: { variant = .countingDown }
                            )
                            VariantButton(
                                title: String(localized: "share_just_binged"),
                                isSelected: variant == .justBinged,
                                isEnabled: canClaimBinged,
                                action: { variant = .justBinged }
                            )
                        }
                        .padding(3)
                        .background(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                        .cornerRadius(10)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)

                        BingeCard(
                            show: show,
                            artwork: backdropImage,
                            orientation: .landscape,
                            seasonNumber: seasonNumber,
                            statBig: statBig,
                            statLabel: statLabel
                        )
                        .padding(.horizontal, 20)

                        postTextCard
                            .padding(.horizontal, 20)
                            .padding(.top, 12)

                        Group {
                            if let handoff {
                                handoffCard(handoff)
                            } else {
                                destinationsRow
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)

                        if let statusNote {
                            Text(statusNote)
                                .font(.system(size: 11.5))
                                .foregroundColor(.c2bMuted)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 20)
                                .padding(.top, 10)
                        }

                        // Catch-all for everywhere else. Picking the
                        // destination is the OS's job, and it already knows
                        // which apps are installed.
                        Button {
                            Task { await presentShare() }
                        } label: {
                            HStack(spacing: 8) {
                                if isPreparing {
                                    ProgressView()
                                        .tint(Color(hex: "#04201c"))
                                } else {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 15, weight: .semibold))
                                }
                                Text("share_button")
                                    .font(.custom(.oswald.bold, size: 15))
                                    .tracking(0.45)
                                    .textCase(.uppercase)
                            }
                            .foregroundColor(Color(hex: "#04201c"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(Color.c2bTeal)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                        .disabled(isPreparing)
                        .padding(.horizontal, 20)
                        .padding(.top, 16)

                        // Cancel button
                        Button(action: { dismissSheet() }) {
                            Text("button_cancel")
                                .font(.custom(.oswald.regular, size: 13))
                                .tracking(0.78)
                                .foregroundColor(.c2bDim)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 13)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.14), lineWidth: 1)
                                )
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 20)
                    }
                    .background(Color(hex: "#0e0e0f"))
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 24,
                            topTrailingRadius: 24
                        )
                    )
                    .overlay(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 24,
                            topTrailingRadius: 24
                        )
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .transition(.move(edge: .bottom))
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: isPresented)
        }
        .onAppear {
            isPresented = true
            if !canClaimBinged { variant = .countingDown }
        }
        .onChange(of: canClaimBinged) { _, available in
            if !available { variant = .countingDown }
        }
        .task { await loadArtwork() }
        .sheet(item: $messagePayload) { payload in
            MessageComposeView(image: payload.image, body: payload.body) {
                messagePayload = nil
                dismissSheet()
            }
        }
        .sheet(isPresented: $isSharing) {
            ActivityShareView(items: shareItems) { completed, activity in
                isSharing = false
                guard completed else { return }
                // "Save to Camera Roll" leaves the user in our app with no
                // system feedback at all, so say it ourselves.
                if activity == .saveToCameraRoll {
                    statusNote = String(localized: "share_status_saved_only")
                } else {
                    dismissSheet()
                }
            }
        }
    }

    // MARK: - Post text

    /// Read-only. Copy exists for the apps that won't take a caption from the
    /// share sheet — the user pastes it into the composer themselves.
    private var postTextCard: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Text("share_post_text")
                    .font(.custom(.jetbrains.regular, size: 9))
                    .tracking(1.35)
                    .textCase(.uppercase)
                    .foregroundColor(.c2bMuted)

                Spacer(minLength: 0)

                Button {
                    UIPasteboard.general.string = postText
                    withAnimation(.easeOut(duration: 0.15)) { didCopy = true }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: didCopy ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 10, weight: .semibold))
                        Text(didCopy ? "share_copied" : "share_copy")
                            .font(.custom(.jetbrains.regular, size: 9))
                            .tracking(1.08)
                            .textCase(.uppercase)
                    }
                    .foregroundColor(.c2bTealBright)
                }
                .buttonStyle(.plain)
            }

            Text(postText)
                .font(.system(size: 14))
                .foregroundColor(.c2bText)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        // A new variant produces new copy, so the "Copied" state is stale.
        .onChange(of: variant) { _, _ in didCopy = false }
    }

    // MARK: - Destinations

    private var destinationsRow: some View {
        HStack(spacing: 8) {
            ForEach(ShareDestination.allCases) { destination in
                Button {
                    Task { await route(to: destination) }
                } label: {
                    VStack(spacing: 6) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color(uiColor: destination.tint))
                                .frame(width: 50, height: 50)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                                )

                            if busyDestination == destination {
                                ProgressView().tint(.white)
                            } else {
                                switch destination.mark {
                                case .symbol(let name):
                                    Image(systemName: name)
                                        .font(.system(size: 19, weight: .semibold))
                                        .foregroundColor(.white)
                                case .text(let mark):
                                    Text(mark)
                                        .font(.custom(.oswald.bold, size: 19))
                                        .tracking(0.6)
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.6)
                                }
                            }
                        }

                        Text(destination.label)
                            .font(.system(size: 10))
                            .foregroundColor(.c2bDim)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                }
                .buttonStyle(.plain)
                .disabled(busyDestination != nil)
                .frame(maxWidth: .infinity)
            }
        }
    }

    /// Messages composes in-app. Everything else saves the card and copies the
    /// caption, then stops on a confirmation step — leaving immediately made it
    /// look like nothing had happened.
    @MainActor
    private func route(to destination: ShareDestination) async {
        busyDestination = destination
        statusNote = nil
        defer { busyDestination = nil }

        await loadArtwork()

        guard let card = renderCard(orientation: destination.wantsPortraitCard ? .portrait : .landscape) else {
            statusNote = String(localized: "share_status_failed")
            return
        }

        if destination.isInAppCompose {
            guard MessageComposeView.canSend else {
                statusNote = String(localized: "share_status_no_messages")
                return
            }
            messagePayload = MessagePayload(image: card, body: postText)
            return
        }

        // Save first. `stage` returns only after PHPhotoLibrary's completion
        // handler fires, so the panel below can't claim the card is in the
        // library before it actually is.
        switch await destination.stage(card: card, caption: postText) {
        case .opened:
            // Instagram Stories took the card straight off the pasteboard.
            dismissSheet()
        case .saved(let localIdentifier):
            // X stops on the panel so the caption can be copied there. TikTok
            // has everything it needs already — card in the library, caption on
            // the clipboard — so it leaves straight away, like Instagram.
            if destination.showsCopyButton {
                didCopyCaption = false
                handoff = Handoff(destination: destination, card: card)
            } else if destination == .tiktok, TikTokShare.isConfigured {
                // Share Kit: opens TikTok's editor with the card loaded.
                // Falls back to just opening TikTok if the SDK refuses.
                if await TikTokShare.share(localIdentifier: localIdentifier) == nil {
                    _ = await destination.open(caption: postText)
                }
                dismissSheet()
            } else {
                _ = await destination.open(caption: postText)
                dismissSheet()
            }
        case .needsPhotoPermission:
            statusNote = String(localized: "share_status_photos_denied")
        case .failed:
            statusNote = String(localized: "share_status_failed")
        }
    }

    /// "Here is what we saved, here is where it's going." The thumbnail is the
    /// actual rendered card, so there is no doubt about what landed in Photos.
    /// Shown only after the save callback confirmed. The image is already in
    /// the library; the one thing left is the caption, so the button copies it.
    private func handoffCard(_ handoff: Handoff) -> some View {
        VStack(spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(uiImage: handoff.card)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 46, height: 62)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.c2bTealBright)
                        Text("share_saved_title")
                            .font(.custom(.jetbrains.bold, size: 9.5))
                            .tracking(1.14)
                            .textCase(.uppercase)
                            .foregroundColor(.c2bTealBright)
                    }

                    Text(handoff.destination.showsCopyButton
                         ? String(localized: "share_saved_body_copy \(handoff.destination.label)")
                         : String(localized: "share_saved_body \(handoff.destination.openTargetLabel)"))
                        .font(.system(size: 12))
                        .foregroundColor(.c2bMuted)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            if handoff.destination.showsCopyButton {
                Button {
                    UIPasteboard.general.string = postText
                    withAnimation(.easeOut(duration: 0.18)) { didCopyCaption = true }
                } label: {
                    HStack(spacing: 7) {
                        Image(systemName: didCopyCaption ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 13, weight: .semibold))
                        Text(didCopyCaption ? "share_copied" : "share_copy")
                            .font(.custom(.oswald.bold, size: 15))
                            .tracking(0.45)
                            .textCase(.uppercase)
                    }
                    .foregroundColor(Color(hex: "#04201c"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.c2bTeal)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            } else {
                Button {
                    Task {
                        _ = await handoff.destination.open(caption: postText)
                        dismissSheet()
                    }
                } label: {
                    Text(handoff.destination.handoffButtonTitle)
                        .font(.custom(.oswald.bold, size: 15))
                        .tracking(0.45)
                        .textCase(.uppercase)
                        .foregroundColor(Color(hex: "#04201c"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.c2bTeal)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }

            Button(String(localized: "share_back_to_destinations")) {
                self.handoff = nil
            }
            .font(.custom(.jetbrains.regular, size: 9))
            .tracking(1.08)
            .textCase(.uppercase)
            .foregroundColor(.c2bMuted)
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.c2bTealLine, lineWidth: 1)
        )
    }

    // MARK: - Share

    /// Render the card and hand it to the OS. The backdrop is usually already
    /// in memory from the detail view, so this is normally instant.
    @MainActor
    private func presentShare() async {
        isPreparing = true
        await loadArtwork()

        var items: [Any] = []
        if let card = renderCard(orientation: .landscape) {
            // The image itself, not a file URL. A file URL arrives as a
            // document attachment; as an image it goes into Messages as an
            // attachment with the post text below it as the message body.
            items.append(ShareCardSource(image: card, title: show.name))
        }
        items.append(postText)
        if let link = AppLinks.appStore { items.append(link) }

        shareItems = items
        isPreparing = false
        isSharing = true
    }

    /// One synchronous frame at 3x. Width is fixed because ImageRenderer has no
    /// parent to size against.
    @MainActor
    private func renderCard(orientation: BingeCardOrientation, scale: CGFloat = 3) -> UIImage? {
        let card = BingeCard(
            show: show,
            artwork: orientation == .portrait ? (posterImage ?? backdropImage) : backdropImage,
            orientation: orientation,
            seasonNumber: seasonNumber,
            statBig: statBig,
            statLabel: statLabel
        )
        .frame(width: orientation.width)

        let renderer = ImageRenderer(content: card)
        renderer.scale = scale
        return renderer.uiImage
    }

    /// Both crops, fetched once. Usually already in memory from the detail view.
    private func loadArtwork() async {
        async let backdrop = Self.image(at: show.backdropURL ?? show.posterURL)
        async let poster = Self.image(at: show.posterURL ?? show.backdropURL)
        let (b, p) = await (backdrop, poster)
        if backdropImage == nil { backdropImage = b }
        if posterImage == nil { posterImage = p }
    }

    private static func image(at url: URL?) async -> UIImage? {
        guard let url else { return nil }
        if let cached = ImageCache.shared.get(for: url) { return cached }
        guard let (data, _) = try? await URLSession.shared.data(from: url),
              let image = UIImage(data: data) else { return nil }
        ImageCache.shared.set(image, for: url)
        return image
    }

    private func dismissSheet() {
        isPresented = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onClose()
        }
    }
}

// MARK: - Variant Button

private struct VariantButton: View {
    let title: String
    let isSelected: Bool
    var isEnabled: Bool = true
    let action: () -> Void

    private var foreground: Color {
        if !isEnabled { return .c2bMuted.opacity(0.45) }
        return isSelected ? Color(hex: "#04201c") : .c2bDim
    }

    var body: some View {
        Button(action: action) {
            Text(title.uppercased())
                .font(.custom(.jetbrains.bold, size: 9.5))
                .tracking(0.76)
                .foregroundColor(foreground)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(isSelected && isEnabled ? Color.c2bTeal : Color.clear)
                .cornerRadius(8)
        }
        .disabled(!isEnabled)
    }
}

// MARK: - Binge Card

/// The two crops a card ships in.
///
/// Messages renders an attachment inline in the bubble, where a wide card reads
/// well. Instagram, TikTok and X are vertical surfaces — a landscape card there
/// sits in a letterboxed band. Same layout either way; only the frame changes.
enum BingeCardOrientation {
    case landscape
    case portrait

    var width: CGFloat { self == .portrait ? 360 : 360 }
    var height: CGFloat { self == .portrait ? 640 : 200 }
}

/// Both variants share one layout — only the stat text differs — so the card
/// can't drift between "counting down" and "just binged".
private struct BingeCard: View {
    let show: ShowData
    /// Pre-resolved artwork. Required for export — ImageRenderer cannot wait
    /// on LazyImage — and used on screen too so the preview matches the file.
    let artwork: UIImage?
    let orientation: BingeCardOrientation
    let seasonNumber: String
    let statBig: String
    let statLabel: String

    private var isPortrait: Bool { orientation == .portrait }
    private var padding: CGFloat { isPortrait ? 22 : 16 }
    private var cornerRadius: CGFloat { isPortrait ? 26 : 20 }

    var body: some View {
        ZStack {
            backdrop

            // Keeps white type legible over a bright frame. Portrait needs a
            // heavier floor because the stat sits lower over more artwork.
            LinearGradient(
                colors: [
                    Color(hex: "#0b0b0c").opacity(isPortrait ? 0.92 : 0.85),
                    Color(hex: "#0b0b0c").opacity(isPortrait ? 0.30 : 0.25),
                    Color(hex: "#0b0b0c").opacity(isPortrait ? 0.80 : 0.75)
                ],
                startPoint: .bottom,
                endPoint: .top
            )

            VStack(spacing: 0) {
                // Logo alone at the top right — a watermark, not a headline.
                HStack {
                    Spacer(minLength: 0)

                    Image("ShareLogo")
                        .resizable()
                        .frame(width: 50, height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 11))
                        .opacity(0.3)
                }

                Spacer(minLength: 12)

                // Title and season bottom left, stat right-aligned against the
                // right edge, sharing one baseline row.
                HStack(alignment: .bottom, spacing: 12) {
                    HStack(alignment: .lastTextBaseline, spacing: 6) {
                        Text(show.name)
                            .font(.custom(.oswald.bold, size: isPortrait ? 28 : 22))
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .minimumScaleFactor(0.6)
                            .multilineTextAlignment(.leading)

                        HStack(spacing: 0) {
                            Text("season_abbrev")
                                .font(.custom(.oswald.bold, size: isPortrait ? 19 : 15))
                            Text(seasonNumber)
                                .font(.custom(.oswald.light, size: isPortrait ? 19 : 15))
                        }
                        .foregroundColor(.white.opacity(0.9))
                        .fixedSize()
                    }
                    .shadow(color: .black.opacity(0.8), radius: 10, y: 2)

                    Spacer(minLength: 0)

                    VStack(alignment: .trailing, spacing: isPortrait ? 5 : 3) {
                        Text(statBig)
                            .font(.custom(.oswald.bold, size: isPortrait ? 76 : 50))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)

                        Text(statLabel.uppercased())
                            .font(.custom(.jetbrains.bold, size: isPortrait ? 12 : 9.5))
                            .tracking(isPortrait ? 1.68 : 1.33)
                            .foregroundColor(.c2bTealBright)
                            .multilineTextAlignment(.trailing)
                    }
                    .fixedSize()
                    .shadow(color: .black.opacity(0.75), radius: 12, y: 2)
                }
            }
            .padding(padding)
        }
        .frame(width: orientation.width, height: orientation.height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.6), radius: 44, y: 16)
    }

    @ViewBuilder
    private var backdrop: some View {
        if let artwork {
            Image(uiImage: artwork)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: orientation.width, height: orientation.height)
                .clipped()
        } else {
            BackdropView(
                url: isPortrait ? (show.posterURL ?? show.backdropURL) : (show.backdropURL ?? show.posterURL),
                height: orientation.height
            )
        }
    }
}
