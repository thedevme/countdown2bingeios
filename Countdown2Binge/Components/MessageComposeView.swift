//
//  MessageComposeView.swift
//  Countdown2Binge
//
//  MFMessageComposeViewController for SwiftUI.
//
//  The one destination with a real pre-fill API: the card goes in as an
//  attachment and the caption as the message body, in a single draft the user
//  only has to address and send.
//

import SwiftUI
import MessageUI

struct MessageComposeView: UIViewControllerRepresentable {
    let image: UIImage
    let body: String
    var onFinish: () -> Void = {}

    /// False on a device with no iMessage/SMS account — the simulator, an iPad
    /// with no plan. Check before presenting or the controller comes up dead.
    static var canSend: Bool { MFMessageComposeViewController.canSendText() }

    func makeCoordinator() -> Coordinator {
        Coordinator(onFinish: onFinish)
    }

    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let controller = MFMessageComposeViewController()
        controller.body = body
        controller.messageComposeDelegate = context.coordinator
        if let data = image.pngData() {
            controller.addAttachmentData(data, typeIdentifier: "public.png", filename: "binge-card.png")
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: MFMessageComposeViewController, context: Context) {}

    final class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        private let onFinish: () -> Void

        init(onFinish: @escaping () -> Void) {
            self.onFinish = onFinish
        }

        func messageComposeViewController(
            _ controller: MFMessageComposeViewController,
            didFinishWith result: MessageComposeResult
        ) {
            onFinish()
        }
    }
}
