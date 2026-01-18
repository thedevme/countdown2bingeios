//
//  OrientationManager.swift
//  Countdown2Binge
//

import SwiftUI
import UIKit
import Combine

class OrientationManager: ObservableObject {
    static let shared = OrientationManager()

    @Published var orientation: UIInterfaceOrientationMask = .portrait

    func lockLandscape() {
        orientation = .landscape
        rotateToLandscape()
    }

    func lockPortrait() {
        orientation = .portrait
        rotateToPortrait()
    }

    private func rotateToLandscape() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .landscapeRight))
        UIViewController.attemptRotationToDeviceOrientation()
    }

    private func rotateToPortrait() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
        UIViewController.attemptRotationToDeviceOrientation()
    }
}
