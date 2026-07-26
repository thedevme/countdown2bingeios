//
//  ProfileModels.swift
//  Countdown2Binge
//
//  Profile data models and avatar definitions.
//

import SwiftUI

// MARK: - Avatar Definition

struct AvatarStyle: Identifiable, Equatable {
    let id: String
    let label: String
    let gradient: [Color]
    let foregroundColor: Color

    static let teal = AvatarStyle(
        id: "teal",
        label: "Teal",
        gradient: [Color(hex: "#2dd4bf"), Color(hex: "#0f766e")],
        foregroundColor: Color(hex: "#04201c")
    )

    static let slate = AvatarStyle(
        id: "slate",
        label: "Slate",
        gradient: [Color(hex: "#3f3f46"), Color(hex: "#18181b")],
        foregroundColor: Color(hex: "#5eead4")
    )

    static let plum = AvatarStyle(
        id: "plum",
        label: "Plum",
        gradient: [Color(hex: "#7e22ce"), Color(hex: "#3b0764")],
        foregroundColor: .white
    )

    static let ember = AvatarStyle(
        id: "ember",
        label: "Ember",
        gradient: [Color(hex: "#dc2626"), Color(hex: "#7f1d1d")],
        foregroundColor: .white
    )

    static let gold = AvatarStyle(
        id: "gold",
        label: "Gold",
        gradient: [Color(hex: "#eab308"), Color(hex: "#854d0e")],
        foregroundColor: Color(hex: "#1c1917")
    )

    static let ocean = AvatarStyle(
        id: "ocean",
        label: "Ocean",
        gradient: [Color(hex: "#0ea5e9"), Color(hex: "#0c4a6e")],
        foregroundColor: .white
    )

    static let all: [AvatarStyle] = [teal, slate, plum, ember, gold, ocean]

    static func style(for id: String) -> AvatarStyle {
        all.first { $0.id == id } ?? teal
    }
}

// MARK: - User Profile

struct UserProfile: Codable, Equatable {
    var name: String
    var avatarId: String
    var hasCustomName: Bool
    var hasCustomImage: Bool

    static let defaultName = "Binge Watcher"

    init(name: String, avatarId: String, hasCustomName: Bool, hasCustomImage: Bool = false) {
        self.name = name
        self.avatarId = avatarId
        self.hasCustomName = hasCustomName
        self.hasCustomImage = hasCustomImage
    }

    static let `default` = UserProfile(
        name: defaultName,
        avatarId: "teal",
        hasCustomName: false,
        hasCustomImage: false
    )

    var avatar: AvatarStyle {
        AvatarStyle.style(for: avatarId)
    }

    var initials: String {
        let parts = name.trimmingCharacters(in: .whitespaces).split(separator: " ").filter { !$0.isEmpty }
        if parts.isEmpty { return "BW" }
        if parts.count == 1 {
            return String(parts[0].prefix(2)).uppercased()
        }
        return String(parts[0].prefix(1) + parts[parts.count - 1].prefix(1)).uppercased()
    }

    // Migration from old format without hasCustomImage
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        avatarId = try container.decode(String.self, forKey: .avatarId)
        hasCustomName = try container.decode(Bool.self, forKey: .hasCustomName)
        hasCustomImage = try container.decodeIfPresent(Bool.self, forKey: .hasCustomImage) ?? false
    }
}

// MARK: - Profile Manager

@MainActor
@Observable
final class ProfileManager {
    static let shared = ProfileManager()

    private let storageKey = "c2b_user_profile"
    private let imageFileName = "profile_avatar.jpg"

    private(set) var profile: UserProfile
    private(set) var avatarImage: UIImage?

    private var imageFileURL: URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?
            .appendingPathComponent(imageFileName)
    }

    private init() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode(UserProfile.self, from: data) {
            self.profile = decoded
        } else {
            self.profile = .default
        }
        loadAvatarImage()
    }

    func updateProfile(_ newProfile: UserProfile) {
        profile = newProfile
        save()
    }

    func updateName(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        profile.name = trimmed.isEmpty ? UserProfile.defaultName : trimmed
        profile.hasCustomName = !trimmed.isEmpty
        save()
    }

    func updateAvatar(_ avatarId: String) {
        profile.avatarId = avatarId
        save()
    }

    func updateAvatarImage(_ image: UIImage?) {
        avatarImage = image
        profile.hasCustomImage = image != nil

        if let image = image {
            saveAvatarImage(image)
        } else {
            deleteAvatarImage()
        }
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func loadAvatarImage() {
        guard profile.hasCustomImage,
              let url = imageFileURL,
              let data = try? Data(contentsOf: url),
              let image = UIImage(data: data) else {
            avatarImage = nil
            return
        }
        avatarImage = image
    }

    private func saveAvatarImage(_ image: UIImage) {
        guard let url = imageFileURL,
              let data = image.jpegData(compressionQuality: 0.8) else { return }
        try? data.write(to: url)
    }

    private func deleteAvatarImage() {
        guard let url = imageFileURL else { return }
        try? FileManager.default.removeItem(at: url)
    }
}
