//
//  MyListOnboardingPage.swift
//  Countdown2Binge
//
//  One TabView page inside MyListOnboardingContainer's fixed-height card.
//  A plain ScrollView anchors short content (the intro page) to the top,
//  leaving a dead gap below it — this centers content vertically when it's
//  shorter than the page, while still scrolling normally if a page's
//  content (or Dynamic Type) ever grows taller than the fixed height.
//

import SwiftUI

struct MyListOnboardingPage<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                // No forced alignment here — each page's own content ends in
                // a Spacer before its buttons, so once it's given the full
                // page height to work with, that Spacer does the real work
                // of pinning the buttons to the bottom.
                content()
                    .frame(minHeight: geo.size.height)
            }
        }
    }
}
