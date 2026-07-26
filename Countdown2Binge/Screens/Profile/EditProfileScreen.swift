//
//  EditProfileScreen.swift
//  Countdown2Binge
//
//  Edit profile screen for name and avatar customization.
//

import SwiftUI
import PhotosUI

struct EditProfileScreen: View {
    @Environment(\.dismiss) private var dismiss

    let isPremium: Bool

    @State private var name: String = ""
    @State private var selectedAvatarId: String = "teal"
    @State private var originalProfile: UserProfile = .default
    @State private var selectedImage: UIImage?
    @State private var showImageOptions = false
    @State private var showCamera = false
    @State private var showPhotoLibrary = false
    @State private var photosPickerItem: PhotosPickerItem?

    private var draftProfile: UserProfile {
        UserProfile(
            name: name.trimmingCharacters(in: .whitespaces).isEmpty
                ? UserProfile.defaultName
                : name.trimmingCharacters(in: .whitespaces),
            avatarId: selectedAvatarId,
            hasCustomName: !name.trimmingCharacters(in: .whitespaces).isEmpty,
            hasCustomImage: selectedImage != nil || (originalProfile.hasCustomImage && selectedImage == nil)
        )
    }

    private var hasChanges: Bool {
        draftProfile.name != originalProfile.name ||
        draftProfile.avatarId != originalProfile.avatarId ||
        selectedImage != nil
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack(spacing: 12) {
                    // Back button
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(hex: "#dddddd"))
                            .frame(width: 38, height: 38)
                            .background(Color.white.opacity(0.05))
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
                            )
                    }

                    Text("header_edit_profile")
                        .font(.custom(.oswald.bold, size: 24))
                        .tracking(0.48)
                        .foregroundColor(.white)

                    Spacer()

                    // Save button
                    Button(action: saveProfile) {
                        Text("button_save")
                            .font(.custom(.jetbrains.bold, size: 9.5))
                            .tracking(1.2)
                            .textCase(.uppercase)
                            .foregroundColor(hasChanges ? Color(hex: "#04201c") : .c2bMuted)
                            .padding(.horizontal, 15)
                            .padding(.vertical, 9)
                            .background(hasChanges ? Color.c2bTeal : Color.white.opacity(0.06))
                            .cornerRadius(999)
                    }
                    .disabled(!hasChanges)
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                .padding(.bottom, 22)

                // Live preview card
                VStack(spacing: 14) {
                    ProfileAvatar(profile: draftProfile, size: 88, showRing: true, customImage: selectedImage)

                    Text(draftProfile.name.uppercased())
                        .font(.custom(.oswald.bold, size: 26))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        if isPremium {
                            Text("★")
                                .font(.system(size: 10))
                        }
                        Text(isPremium ? "profile_premium_member" : "account_free_plan")
                            .font(.custom(.jetbrains.regular, size: 9))
                            .tracking(1.2)
                            .textCase(.uppercase)
                    }
                    .foregroundColor(isPremium ? .c2bTealBright : .c2bMuted)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 26)
                .padding(.horizontal, 18)
                .background(
                    LinearGradient(
                        colors: [Color.c2bTeal.opacity(0.12), Color.c2bTeal.opacity(0.01)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.c2bTealLine, lineWidth: 1)
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 26)

                // Display name field
                VStack(alignment: .leading, spacing: 10) {
                    Text("profile_display_name")
                        .font(.custom(.jetbrains.regular, size: 9))
                        .tracking(1.6)
                        .textCase(.uppercase)
                        .foregroundColor(.c2bMuted)

                    ZStack(alignment: .trailing) {
                        TextField(UserProfile.defaultName, text: $name)
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .padding(.vertical, 15)
                            .padding(.horizontal, 16)
                            .padding(.trailing, name.isEmpty ? 0 : 40)
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )

                        if !name.isEmpty {
                            Button(action: { name = "" }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.c2bDim)
                                    .frame(width: 24, height: 24)
                                    .background(Color.white.opacity(0.1))
                                    .clipShape(Circle())
                            }
                            .padding(.trailing, 12)
                        }
                    }

                    HStack {
                        Text("profile_name_hint")
                            .font(.custom(.jetbrains.regular, size: 8.5))
                            .tracking(0.8)
                            .textCase(.uppercase)
                            .foregroundColor(.c2bMuted)

                        Spacer()

                        Text("\(name.count)/24")
                            .font(.custom(.jetbrains.regular, size: 8.5))
                            .tracking(0.8)
                            .foregroundColor(.c2bMuted)
                    }
                }
                .padding(.horizontal, 20)

                // Avatar color picker
                VStack(alignment: .leading, spacing: 12) {
                    Text("profile_avatar_color")
                        .font(.custom(.jetbrains.regular, size: 9))
                        .tracking(1.6)
                        .textCase(.uppercase)
                        .foregroundColor(.c2bMuted)
                        .padding(.top, 26)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 6), spacing: 10) {
                        ForEach(AvatarStyle.all) { style in
                            Button(action: { selectedAvatarId = style.id }) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: style.gradient,
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )

                                    if selectedAvatarId == style.id {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(style.foregroundColor)
                                    }
                                }
                                .aspectRatio(1, contentMode: .fit)
                                .overlay(
                                    Circle()
                                        .stroke(
                                            selectedAvatarId == style.id
                                                ? Color.c2bTealBright
                                                : Color.white.opacity(0.14),
                                            lineWidth: selectedAvatarId == style.id ? 2 : 1
                                        )
                                )
                                .shadow(
                                    color: selectedAvatarId == style.id ? Color.c2bTeal.opacity(0.18) : .clear,
                                    radius: selectedAvatarId == style.id ? 8 : 0
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }

                    Text("profile_initials_hint")
                        .font(.custom(.jetbrains.regular, size: 8.5))
                        .tracking(0.8)
                        .textCase(.uppercase)
                        .foregroundColor(.c2bMuted)
                        .padding(.top, 2)
                }
                .padding(.horizontal, 20)

                // Photo upload (premium feature)
                VStack(alignment: .leading, spacing: 12) {
                    Text("profile_photo")
                        .font(.custom(.jetbrains.regular, size: 9))
                        .tracking(1.6)
                        .textCase(.uppercase)
                        .foregroundColor(.c2bMuted)
                        .padding(.top, 26)

                    Button(action: { if isPremium { showImageOptions = true } }) {
                        HStack(spacing: 13) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 11)
                                    .fill(Color.c2bTeal.opacity(0.1))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 11)
                                            .stroke(Color.c2bTealLine, lineWidth: 1)
                                    )

                                Image(systemName: "camera.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.c2bTealBright)
                            }

                            VStack(alignment: .leading, spacing: 3) {
                                Text("profile_upload_photo")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)

                                Text(isPremium ? "profile_choose_library" : "profile_premium_feature")
                                    .font(.system(size: 11.5))
                                    .foregroundColor(.c2bMuted)
                            }

                            Spacer()

                            if !isPremium {
                                Text("PRO")
                                    .font(.custom(.jetbrains.bold, size: 8))
                                    .tracking(1.0)
                                    .foregroundColor(.c2bTealBright)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.c2bTeal.opacity(0.12))
                                    .cornerRadius(999)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 999)
                                            .stroke(Color.c2bTealLine, lineWidth: 1)
                                    )
                            } else if selectedImage != nil || originalProfile.hasCustomImage {
                                Button(action: { selectedImage = nil; ProfileManager.shared.updateAvatarImage(nil) }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.c2bMuted)
                                }
                            }
                        }
                        .padding(15)
                        .background(Color.white.opacity(0.03))
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(
                                    style: StrokeStyle(lineWidth: 1, dash: [5])
                                )
                                .foregroundColor(Color.white.opacity(0.16))
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(!isPremium)
                }
                .padding(.horizontal, 20)

                // Save button
                Button(action: saveProfile) {
                    Text("profile_save_button")
                        .font(.custom(.oswald.bold, size: 16))
                        .tracking(0.32)
                        .foregroundColor(Color(hex: "#04201c"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.c2bTeal)
                        .cornerRadius(14)
                }
                .padding(.horizontal, 20)
                .padding(.top, 28)

                // Cancel button
                Button(action: { dismiss() }) {
                    Text("button_cancel")
                        .font(.custom(.jetbrains.bold, size: 10.5))
                        .tracking(1.4)
                        .textCase(.uppercase)
                        .foregroundColor(.c2bMuted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)

                Spacer()
                    .frame(height: 150)
            }
        }
        .background(Color.c2bBackground)
        .onAppear {
            loadProfile()
        }
        .confirmationDialog("profile_choose_photo", isPresented: $showImageOptions, titleVisibility: .visible) {
            Button(String(localized: "profile_take_photo")) {
                showCamera = true
            }
            Button(String(localized: "profile_choose_from_library")) {
                showPhotoLibrary = true
            }
            if selectedImage != nil || originalProfile.hasCustomImage {
                Button(String(localized: "profile_remove_photo"), role: .destructive) {
                    selectedImage = nil
                    ProfileManager.shared.updateAvatarImage(nil)
                }
            }
            Button(String(localized: "button_cancel"), role: .cancel) {}
        }
        .fullScreenCover(isPresented: $showCamera) {
            ImagePicker(sourceType: .camera) { image in
                selectedImage = image
            }
            .ignoresSafeArea()
        }
        .photosPicker(isPresented: $showPhotoLibrary, selection: $photosPickerItem, matching: .images)
        .onChange(of: photosPickerItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    selectedImage = image
                }
            }
        }
    }

    private func loadProfile() {
        originalProfile = ProfileManager.shared.profile
        name = originalProfile.hasCustomName ? originalProfile.name : ""
        selectedAvatarId = originalProfile.avatarId
        if originalProfile.hasCustomImage {
            selectedImage = ProfileManager.shared.avatarImage
        }
    }

    private func saveProfile() {
        if selectedImage != ProfileManager.shared.avatarImage {
            ProfileManager.shared.updateAvatarImage(selectedImage)
        }
        ProfileManager.shared.updateProfile(draftProfile)
        dismiss()
    }
}

#Preview {
    EditProfileScreen(isPremium: false)
        .preferredColorScheme(.dark)
}
