//
//  OnboardingSlideData.swift
//  Countdown2Binge
//
//  Data models for onboarding slides. Loads structure from JSON,
//  resolves text from Localizable.strings for localization support.
//

import Foundation

// MARK: - Slide Types

enum OnboardingSlideType: String, Codable {
    case hero           // Welcome screen with poster fan
    case problem        // Pain point with illustration
    case stat           // Big number/statistic
    case question       // Single or multi-select question
    case recap          // Summary of user's answers
    case addShows       // Show search/selection
    case tour           // Quick tour modal
    case buckets        // Four states explanation
    case reviewPrompt   // App Store rating
    case notifPriming   // Notification permission
    case summary        // Journey confirmation
    case paywall        // Pricing options (existing)
}

// MARK: - JSON Models (raw from file)

struct OnboardingSlidesJSON: Codable {
    let slides: [SlideJSON]
    let questions: [QuestionJSON]
    let statVariants: [StatVariantJSON]
    let buckets: [BucketJSON]
}

struct SlideJSON: Codable {
    let id: String
    let type: OnboardingSlideType
    let step: Int
    let labelKey: String?
    let headlineKey: String
    let headlineAccentKey: String?
    let bodyKey: String?
    let stat: String?
    let statLabelKey: String?
    let attributionKey: String?
    let buttonKey: String
    let buttonAltKey: String?
}

struct QuestionJSON: Codable {
    let id: String
    let step: Int
    let questionNumber: Int
    let totalQuestions: Int
    let headlineKey: String
    let headlineAccentKey: String
    let bodyKey: String?
    let allowsMultiple: Bool
    let buttonKey: String
    let options: [QuestionOptionJSON]
}

struct QuestionOptionJSON: Codable {
    let id: String
    let labelKey: String
    let icon: String?
    let iconColor: String?
}

struct StatVariantJSON: Codable {
    let behaviorId: String
    let subheadKey: String
}

struct BucketJSON: Codable {
    let id: String
    let titleKey: String
    let descriptionKey: String
    let isHighlighted: Bool
}

// MARK: - Resolved Models (with localized strings)

struct OnboardingSlide: Identifiable {
    let id: String
    let type: OnboardingSlideType
    let step: Int
    let label: String?
    let headline: String
    let headlineAccent: String?
    let body: String?
    let stat: String?
    let statLabel: String?
    let attribution: String?
    let buttonText: String
    let buttonTextAlt: String?
}

struct OnboardingQuestion: Identifiable {
    let id: String
    let step: Int
    let questionNumber: Int
    let totalQuestions: Int
    let headline: String
    let headlineAccent: String
    let body: String?
    let allowsMultiple: Bool
    let buttonText: String
    let options: [QuestionOption]
}

struct QuestionOption: Identifiable, Hashable {
    let id: String
    let label: String
    let icon: String?
    let iconColor: String?
}

struct StatVariant: Identifiable {
    let id: String  // matches behaviorId
    let subhead: String
}

struct BucketInfo: Identifiable {
    let id: String
    let title: String
    let description: String
    let isHighlighted: Bool
}

// MARK: - Data Loader

final class OnboardingDataLoader {
    static let shared = OnboardingDataLoader()

    private var slidesJSON: OnboardingSlidesJSON?

    private init() {
        loadJSON()
    }

    private func loadJSON() {
        guard let url = Bundle.main.url(forResource: "OnboardingSlides", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            return
        }

        do {
            slidesJSON = try JSONDecoder().decode(OnboardingSlidesJSON.self, from: data)
        } catch {
        }
    }

    // MARK: - Localized String Helper

    private func localized(_ key: String) -> String {
        NSLocalizedString(key, comment: "")
    }

    private func localized(_ key: String?) -> String? {
        guard let key = key else { return nil }
        return localized(key)
    }

    // MARK: - Public Accessors

    func slide(for id: String) -> OnboardingSlide? {
        guard let json = slidesJSON?.slides.first(where: { $0.id == id }) else {
            return nil
        }
        return resolveSlide(json)
    }

    func question(for id: String) -> OnboardingQuestion? {
        guard let json = slidesJSON?.questions.first(where: { $0.id == id }) else {
            return nil
        }
        return resolveQuestion(json)
    }

    func statVariant(for behaviorId: String) -> StatVariant? {
        guard let json = slidesJSON?.statVariants.first(where: { $0.behaviorId == behaviorId }) else {
            return nil
        }
        return StatVariant(id: json.behaviorId, subhead: localized(json.subheadKey))
    }

    var allSlides: [OnboardingSlide] {
        slidesJSON?.slides.map { resolveSlide($0) } ?? []
    }

    var allQuestions: [OnboardingQuestion] {
        slidesJSON?.questions.map { resolveQuestion($0) } ?? []
    }

    var allBuckets: [BucketInfo] {
        slidesJSON?.buckets.map { resolveBucket($0) } ?? []
    }

    // MARK: - Resolution

    private func resolveSlide(_ json: SlideJSON) -> OnboardingSlide {
        OnboardingSlide(
            id: json.id,
            type: json.type,
            step: json.step,
            label: localized(json.labelKey),
            headline: localized(json.headlineKey),
            headlineAccent: localized(json.headlineAccentKey),
            body: localized(json.bodyKey),
            stat: json.stat,
            statLabel: localized(json.statLabelKey),
            attribution: localized(json.attributionKey),
            buttonText: localized(json.buttonKey),
            buttonTextAlt: localized(json.buttonAltKey)
        )
    }

    private func resolveQuestion(_ json: QuestionJSON) -> OnboardingQuestion {
        OnboardingQuestion(
            id: json.id,
            step: json.step,
            questionNumber: json.questionNumber,
            totalQuestions: json.totalQuestions,
            headline: localized(json.headlineKey),
            headlineAccent: localized(json.headlineAccentKey),
            body: localized(json.bodyKey),
            allowsMultiple: json.allowsMultiple,
            buttonText: localized(json.buttonKey),
            options: json.options.map { resolveOption($0) }
        )
    }

    private func resolveOption(_ json: QuestionOptionJSON) -> QuestionOption {
        QuestionOption(
            id: json.id,
            label: localized(json.labelKey),
            icon: json.icon,
            iconColor: json.iconColor
        )
    }

    private func resolveBucket(_ json: BucketJSON) -> BucketInfo {
        BucketInfo(
            id: json.id,
            title: localized(json.titleKey),
            description: localized(json.descriptionKey),
            isHighlighted: json.isHighlighted
        )
    }
}

// MARK: - Convenience Extensions

extension OnboardingDataLoader {
    // Quick accessors for common slides
    var welcomeSlide: OnboardingSlide? { slide(for: "welcome") }
    var problemSlide: OnboardingSlide? { slide(for: "problem") }
    var agitateSlide: OnboardingSlide? { slide(for: "agitate") }
    var solutionSlide: OnboardingSlide? { slide(for: "solution") }
    var statSlide: OnboardingSlide? { slide(for: "stat") }
    var reflectionSlide: OnboardingSlide? { slide(for: "reflection") }
    var bucketsSlide: OnboardingSlide? { slide(for: "buckets") }
    var reviewPromptSlide: OnboardingSlide? { slide(for: "review-prompt") }
    var notifPrimingSlide: OnboardingSlide? { slide(for: "notif-priming") }
    var journeySummarySlide: OnboardingSlide? { slide(for: "journey-summary") }
    var priceAnchorSlide: OnboardingSlide? { slide(for: "price-anchor") }

    // Quick accessors for questions
    var genresQuestion: OnboardingQuestion? { question(for: "genres") }
    var servicesQuestion: OnboardingQuestion? { question(for: "services") }
    var behaviorQuestion: OnboardingQuestion? { question(for: "behavior") }
    var commitmentQuestion: OnboardingQuestion? { question(for: "commitment") }
}
