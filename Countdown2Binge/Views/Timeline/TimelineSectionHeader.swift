//
//  TimelineSectionHeader.swift
//  Countdown2Binge
//

import SwiftUI

/// Collapsible section header for Timeline sections
struct TimelineSectionHeader: View {
    let title: String
    let totalCount: Int
    @Binding var isExpanded: Bool
    var showDisclosure: Bool = true
    var style: TimelineCardStyle = .premiering

    private var accentColor: Color {
        switch style {
        case .endingSoon, .premiering:
            return Color(red: 0.45, green: 0.90, blue: 0.70)
        case .anticipated:
            return Color(white: 0.4)
        }
    }

    var body: some View {
        if showDisclosure {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isExpanded.toggle()
                }
            } label: {
                headerContent
            }
            .buttonStyle(.plain)
        } else {
            headerContent
        }
    }

    private var headerContent: some View {
        HStack(spacing: 0) {
            // Badge aligned with timeline (centered in 80px area)
            Text("\(totalCount)")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(accentColor)
                .frame(width: 24, height: 24)
                .background(
                    Circle()
                        .fill(accentColor.opacity(0.15))
                )
                .frame(width: 80)

            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(Color(white: 0.5))

            Spacer()

            // Disclosure arrow (only if showDisclosure)
            if showDisclosure {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color(white: 0.4))
                    .rotationEffect(.degrees(isExpanded ? 0 : 90))
            }
        }
        .padding(.trailing, 24)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}

#Preview("Expanded") {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack {
            TimelineSectionHeader(
                title: "PREMIERING SOON",
                totalCount: 6,
                isExpanded: .constant(true)
            )
            Spacer()
        }
    }
}

#Preview("Collapsed") {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack {
            TimelineSectionHeader(
                title: "ANTICIPATED",
                totalCount: 3,
                isExpanded: .constant(false)
            )
            Spacer()
        }
    }
}
