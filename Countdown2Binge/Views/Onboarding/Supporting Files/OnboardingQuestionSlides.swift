//
//  OnboardingQuestionSlides.swift
//  Countdown2Binge
//
//  v2 onboarding — questions & insight (Genres · Services · Behavior · Stat ·
//  Reflection). Layout is the v2 design; all copy is loaded from
//  OnboardingSlides.json + Localizable.strings via OnboardingDataLoader.
//  Selections store option IDs, so the behavior answer resolves the stat variant.
//

import SwiftUI

// Reuses the shared `FlowLayout` (spacing + lineSpacing) from ShowDetailMetadataRow.

private let onboardingData = OnboardingDataLoader.shared

private func questionEyebrow(_ q: OnboardingQuestion) -> String {
    String(format: NSLocalizedString("onboarding_question_of %lld %lld", comment: ""), q.questionNumber, q.totalQuestions)
}

/// Trailing "SELECT ALL / CLEAR ALL" toggle for the multi-select questions.
private struct OBSelectAllButton: View {
    let allIds: [String]
    @Binding var picked: Set<String>

    private var allSelected: Bool { !allIds.isEmpty && Set(allIds).isSubset(of: picked) }

    var body: some View {
        Button {
            if allSelected {
                allIds.forEach { picked.remove($0) }
            } else {
                allIds.forEach { picked.insert($0) }
            }
        } label: {
            Text(String(localized: allSelected ? "onboarding_clear_all" : "onboarding_select_all"))
                .font(.custom(.jetbrains.bold, size: 10))
                .tracking(1.0)
                .foregroundColor(.c2bTeal)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
}

// MARK: - 05 Genres

struct OBGenresSlide: View {
    @Binding var picked: Set<String>

    var body: some View {
        if let q = onboardingData.genresQuestion {
            OBSlide(eyebrow: questionEyebrow(q), title: q.headline, accent: q.headlineAccent, message: q.body) {
                VStack(alignment: .leading, spacing: 12) {
                    OBSelectAllButton(allIds: q.options.map { $0.id }, picked: $picked)
                    FlowLayout(spacing: 8) {
                        ForEach(q.options) { option in
                            let on = picked.contains(option.id)
                            Button { toggle(option.id) } label: {
                                Text(option.label)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(on ? .c2bOnTeal : .c2bDim)
                                    .padding(.horizontal, 14).padding(.vertical, 10)
                                    .background(on ? Color.c2bTeal : Color.white.opacity(0.04))
                                    .clipShape(Capsule())
                                    .overlay(Capsule().stroke(on ? Color.c2bTeal : Color.white.opacity(0.1), lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.top, 18)
            }
        }
    }

    private func toggle(_ id: String) {
        if picked.contains(id) { picked.remove(id) } else { picked.insert(id) }
    }
}

// MARK: - 06 Services

struct OBServicesSlide: View {
    @Binding var picked: Set<String>
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 9), count: 3)

    // Brand colors keyed by JSON option id (not in the localized strings).
    private let colors: [String: String] = [
        "netflix": "#E50914", "max": "#5A35E0", "hulu": "#1CE783", "disney": "#1FA2FF",
        "appletv": "#9aa0a6", "prime": "#1FB6FF", "paramount": "#0064FF", "peacock": "#F5C518", "other": "#52525b",
    ]
    private func isLight(_ id: String) -> Bool { id == "appletv" || id == "peacock" }

    var body: some View {
        if let q = onboardingData.servicesQuestion {
            OBSlide(eyebrow: questionEyebrow(q), title: q.headline, accent: q.headlineAccent, message: q.body) {
                VStack(alignment: .leading, spacing: 12) {
                    OBSelectAllButton(allIds: q.options.map { $0.id }, picked: $picked)
                    LazyVGrid(columns: columns, spacing: 9) {
                    ForEach(q.options) { option in
                        let on = picked.contains(option.id)
                        Button { toggle(option.id) } label: {
                            VStack(spacing: 7) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 9)
                                        .fill(Color(hex: colors[option.id] ?? "#52525b"))
                                        .frame(width: 30, height: 30)
                                    Text(String(option.label.prefix(1)))
                                        .font(.custom(.oswald.bold, size: 15))
                                        .foregroundColor(isLight(option.id) ? Color(hex: "#0a0a0b") : .white)
                                }
                                Text(option.label)
                                    .font(.system(size: 10.5, weight: .semibold))
                                    .foregroundColor(on ? .c2bText : .c2bMuted)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14).padding(.horizontal, 6)
                            .background(on ? Color.c2bTeal.opacity(0.10) : Color.white.opacity(0.03))
                            .clipShape(RoundedRectangle(cornerRadius: 13))
                            .overlay(RoundedRectangle(cornerRadius: 13).stroke(on ? Color.c2bTeal : Color.white.opacity(0.09), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                    }
                }
                .padding(.top, 18)
            }
        }
    }

    private func toggle(_ id: String) {
        if picked.contains(id) { picked.remove(id) } else { picked.insert(id) }
    }
}

// MARK: - 07 Behavior

struct OBBehaviorSlide: View {
    @Binding var answer: String?

    var body: some View {
        if let q = onboardingData.behaviorQuestion {
            OBSlide(eyebrow: questionEyebrow(q), title: q.headline, accent: q.headlineAccent) {
                VStack(spacing: 9) {
                    ForEach(q.options) { option in
                        OBRadioRow(text: option.label, selected: answer == option.id) { answer = option.id }
                    }
                }
                .padding(.top, 24)
            }
        }
    }
}

/// Shared radio row used by Behavior + Commitment.
struct OBRadioRow: View {
    let text: String
    let selected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(selected ? Color.c2bTeal : Color.clear)
                        .overlay(Circle().stroke(selected ? Color.clear : Color.white.opacity(0.25), lineWidth: 1.5))
                        .frame(width: 20, height: 20)
                    if selected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .heavy))
                            .foregroundColor(.c2bOnTeal)
                    }
                }
                Text(text)
                    .font(.system(size: 13.5, weight: selected ? .semibold : .medium))
                    .foregroundColor(selected ? .c2bText : .c2bDim)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(15)
            .background(selected ? Color.c2bTeal.opacity(0.09) : Color.white.opacity(0.03))
            .clipShape(RoundedRectangle(cornerRadius: 13))
            .overlay(RoundedRectangle(cornerRadius: 13).stroke(selected ? Color.c2bTealLine : Color.white.opacity(0.09), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 08 Aha Stat (count-up, subhead varies by behavior answer)

struct OBStatSlide: View {
    /// The behavior option id chosen on the previous step.
    let behavior: String?
    @State private var displayed = 0

    private var slide: OnboardingSlide? { onboardingData.statSlide }
    private var target: Int { Int(slide?.stat ?? "0") ?? 0 }
    private var subhead: String? {
        guard let behavior else { return nil }
        return onboardingData.statVariant(for: behavior)?.subhead
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let label = slide?.label {
                Text(label)
                    .font(.custom(.jetbrains.regular, size: 10))
                    .tracking(2.0)
                    .foregroundColor(.c2bTeal)
            }

            if let headline = slide?.headline {
                Text(headline)
                    .font(.custom(.oswald.bold, size: 34))
                    .foregroundColor(.white)
                    .textCase(.uppercase)
                    .lineSpacing(0)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 14)
            }

            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text("\(displayed)")
                    .font(.custom(.oswald.bold, size: 92))
                    .foregroundColor(.c2bTealBright)
                if let unit = slide?.statLabel {
                    Text(unit)
                        .font(.custom(.oswald.bold, size: 30))
                        .foregroundColor(.c2bTeal)
                }
            }
            .padding(.top, 14).padding(.bottom, 6)

            if let subhead {
                Text(subhead)
                    .font(.system(size: 14.5))
                    .foregroundColor(.c2bDim)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 14)
            }

            if let attribution = slide?.attribution {
                Text(attribution)
                    .font(.custom(.jetbrains.regular, size: 9))
                    .tracking(0.9)
                    .foregroundColor(.c2bMuted)
                    .padding(.top, 18)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear { runCountUp() }
    }

    private func runCountUp() {
        guard target > 0 else { return }
        displayed = 0
        for i in 0...target {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * (1.0 / Double(max(target, 1)))) {
                displayed = i
            }
        }
    }
}

// MARK: - 09 Reflection

struct OBReflectionSlide: View {
    let genres: Set<String>
    let services: Set<String>
    let behavior: String?

    private var slide: OnboardingSlide? { onboardingData.reflectionSlide }

    private func label(forGenre id: String) -> String {
        onboardingData.genresQuestion?.options.first { $0.id == id }?.label ?? id
    }

    private var genreString: String {
        let labels = genres.map { label(forGenre: $0) }
        if labels.isEmpty { return "a bit of everything" }
        if labels.count <= 2 { return labels.joined(separator: " and ") }
        return "\(labels[0]), \(labels[1]) and \(labels.count - 2) more"
    }

    private var serviceString: String {
        let n = services.count
        if n == 0 { return "at least one service" }
        return String(format: NSLocalizedString("onboarding_reflection_services_count %lld", comment: ""), n)
    }

    private var behaviorString: String {
        guard let behavior,
              let label = onboardingData.behaviorQuestion?.options.first(where: { $0.id == behavior })?.label
        else { return "by chance" }
        return label
    }

    private var rows: [(String, String)] {
        [(String(localized: "onboarding_reflection_you_watch"), genreString),
         (String(localized: "onboarding_reflection_you_pay"), serviceString),
         (String(localized: "onboarding_reflection_you_find"), behaviorString)]
    }

    var body: some View {
        OBSlide(eyebrow: slide?.label ?? "RECAP",
                title: slide?.headline ?? "HERE'S WHAT",
                accent: slide?.headlineAccent ?? "YOU TOLD US.") {
            VStack(spacing: 10) {
                ForEach(rows, id: \.0) { key, value in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(key.uppercased())
                            .font(.custom(.jetbrains.regular, size: 8.5))
                            .tracking(1.19)
                            .foregroundColor(.c2bMuted)
                        Text(value)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.c2bText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 15).padding(.vertical, 14)
                    .background(Color.white.opacity(0.03))
                    .clipShape(RoundedRectangle(cornerRadius: 13))
                    .overlay(RoundedRectangle(cornerRadius: 13).stroke(Color.white.opacity(0.08), lineWidth: 1))
                }
            }
            .padding(.top, 26)

            if let body = slide?.body {
                Text(body)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.c2bTealBright)
                    .padding(.top, 20)
            }
        }
    }
}
