import SwiftUI
import SwiftData
import PhotosUI

struct BrandKitView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var brandKits: [BrandKit]

    // Logo
    @State private var logoImageData: Data?
    @State private var logoPosition: LogoPosition = .topRight
    @State private var selectedLogoItem: PhotosPickerItem?

    // Contact info
    @State private var businessName: String = ""
    @State private var phone: String = ""
    @State private var email: String = ""
    @State private var website: String = ""
    @State private var address: String = ""
    @State private var socialHandle: String = ""

    // QR Code
    @State private var qrSettings: QRCodeSettings = QRCodeSettings()

    // UI state
    @State private var showingDeleteConfirmation = false
    @State private var hasChanges = false

    private var brandKit: BrandKit? { brandKits.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: FGSpacing.lg) {
                    headerCard

                    logoSection

                    contactSection

                    qrCodeSection

                    saveButton

                    if brandKit != nil {
                        deleteButton
                    }
                }
                .padding(.vertical, FGSpacing.lg)
            }
            .background(FGColors.backgroundPrimary)
            .navigationTitle("Brand Kit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(FGColors.accentPrimary)
                }
            }
            .toolbarBackground(FGColors.backgroundPrimary, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
        .onAppear { loadFromBrandKit() }
        .onChange(of: selectedLogoItem) { _, newItem in
            Task { await loadLogo(from: newItem) }
        }
        .alert("Delete Brand Kit?", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) { deleteBrandKit() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove all your saved brand details. This cannot be undone.")
        }
    }

    // MARK: - Header

    private var headerCard: some View {
        HStack(spacing: FGSpacing.sm) {
            Image(systemName: "briefcase.fill")
                .font(.title2)
                .foregroundColor(FGColors.accentPrimary)

            VStack(alignment: .leading, spacing: FGSpacing.xxxs) {
                Text("Your Brand Kit")
                    .font(FGTypography.h4)
                    .foregroundColor(FGColors.textPrimary)
                Text("Save your brand details once. They'll auto-fill when you create new flyers.")
                    .font(FGTypography.caption)
                    .foregroundColor(FGColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(FGSpacing.cardPadding)
        .background(FGColors.accentPrimary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: FGSpacing.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: FGSpacing.cardRadius)
                .stroke(FGColors.accentPrimary.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, FGSpacing.screenHorizontal)
    }

    // MARK: - Logo Section

    private var logoSection: some View {
        VStack(alignment: .leading, spacing: FGSpacing.sm) {
            Text("Logo")
                .font(FGTypography.h4)
                .foregroundColor(FGColors.textSecondary)
                .padding(.horizontal, FGSpacing.screenHorizontal)

            VStack(spacing: FGSpacing.md) {
                // Logo preview / picker
                if let logoData = logoImageData, let uiImage = UIImage(data: logoData) {
                    VStack(spacing: FGSpacing.sm) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 120)
                            .clipShape(RoundedRectangle(cornerRadius: FGSpacing.inputRadius))

                        HStack(spacing: FGSpacing.sm) {
                            PhotosPicker(selection: $selectedLogoItem, matching: .images) {
                                Label("Change", systemImage: "photo")
                                    .font(FGTypography.label)
                                    .foregroundColor(FGColors.accentPrimary)
                            }

                            Button {
                                logoImageData = nil
                                selectedLogoItem = nil
                            } label: {
                                Label("Remove", systemImage: "trash")
                                    .font(FGTypography.label)
                                    .foregroundColor(FGColors.error)
                            }
                        }
                    }
                } else {
                    PhotosPicker(selection: $selectedLogoItem, matching: .images) {
                        VStack(spacing: FGSpacing.sm) {
                            Image(systemName: "photo.badge.plus")
                                .font(.system(size: 32))
                                .foregroundColor(FGColors.textTertiary)
                            Text("Add Logo")
                                .font(FGTypography.label)
                                .foregroundColor(FGColors.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 100)
                        .background(FGColors.surfaceDefault)
                        .clipShape(RoundedRectangle(cornerRadius: FGSpacing.inputRadius))
                        .overlay(
                            RoundedRectangle(cornerRadius: FGSpacing.inputRadius)
                                .stroke(FGColors.borderSubtle, lineWidth: 1)
                        )
                    }
                }

                // Logo position
                if logoImageData != nil {
                    VStack(alignment: .leading, spacing: FGSpacing.xs) {
                        Text("Logo Position")
                            .font(FGTypography.label)
                            .foregroundColor(FGColors.textSecondary)

                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: FGSpacing.xs) {
                            ForEach(LogoPosition.allCases) { position in
                                LogoPositionButton(
                                    position: position,
                                    isSelected: logoPosition == position
                                ) {
                                    logoPosition = position
                                }
                            }
                        }
                    }
                }
            }
            .padding(FGSpacing.cardPadding)
            .background(FGColors.backgroundElevated)
            .clipShape(RoundedRectangle(cornerRadius: FGSpacing.cardRadius))
            .overlay(
                RoundedRectangle(cornerRadius: FGSpacing.cardRadius)
                    .stroke(FGColors.borderSubtle, lineWidth: 1)
            )
            .padding(.horizontal, FGSpacing.screenHorizontal)
        }
    }

    // MARK: - Contact Section

    private var contactSection: some View {
        VStack(alignment: .leading, spacing: FGSpacing.sm) {
            Text("Contact Information")
                .font(FGTypography.h4)
                .foregroundColor(FGColors.textSecondary)
                .padding(.horizontal, FGSpacing.screenHorizontal)

            VStack(spacing: FGSpacing.sm) {
                FGTextField(placeholder: "Business Name", text: $businessName, icon: "building.2")
                FGTextField(placeholder: "Phone", text: $phone, icon: "phone")
                FGTextField(placeholder: "Email", text: $email, icon: "envelope")
                FGTextField(placeholder: "Website", text: $website, icon: "globe")
                FGTextField(placeholder: "Address", text: $address, icon: "mappin")
                FGTextField(placeholder: "Social Handle", text: $socialHandle, icon: "at")
            }
            .padding(FGSpacing.cardPadding)
            .background(FGColors.backgroundElevated)
            .clipShape(RoundedRectangle(cornerRadius: FGSpacing.cardRadius))
            .overlay(
                RoundedRectangle(cornerRadius: FGSpacing.cardRadius)
                    .stroke(FGColors.borderSubtle, lineWidth: 1)
            )
            .padding(.horizontal, FGSpacing.screenHorizontal)
        }
    }

    // MARK: - QR Code Section

    private var qrCodeSection: some View {
        VStack(alignment: .leading, spacing: FGSpacing.sm) {
            Text("QR Code Defaults")
                .font(FGTypography.h4)
                .foregroundColor(FGColors.textSecondary)
                .padding(.horizontal, FGSpacing.screenHorizontal)

            VStack(spacing: FGSpacing.md) {
                // Enable toggle
                Toggle(isOn: $qrSettings.enabled) {
                    Label {
                        Text("Enable QR Code")
                            .font(FGTypography.body)
                            .foregroundColor(FGColors.textPrimary)
                    } icon: {
                        Image(systemName: "qrcode")
                            .foregroundColor(FGColors.accentPrimary)
                    }
                }
                .tint(FGColors.accentPrimary)

                if qrSettings.enabled {
                    // Content type picker
                    VStack(alignment: .leading, spacing: FGSpacing.xs) {
                        Text("Content Type")
                            .font(FGTypography.label)
                            .foregroundColor(FGColors.textSecondary)

                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: FGSpacing.xs) {
                            ForEach(QRContentType.allCases) { type in
                                Button {
                                    qrSettings.contentType = type
                                } label: {
                                    VStack(spacing: FGSpacing.xxs) {
                                        Image(systemName: type.icon)
                                            .font(.system(size: 16))
                                        Text(type.displayName)
                                            .font(FGTypography.captionSmall)
                                            .lineLimit(1)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, FGSpacing.sm)
                                    .background(qrSettings.contentType == type ? FGColors.accentPrimary : FGColors.surfaceDefault)
                                    .foregroundColor(qrSettings.contentType == type ? FGColors.textOnAccent : FGColors.textSecondary)
                                    .clipShape(RoundedRectangle(cornerRadius: FGSpacing.buttonRadius))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: FGSpacing.buttonRadius)
                                            .stroke(qrSettings.contentType == type ? FGColors.accentPrimary : FGColors.borderSubtle, lineWidth: 1)
                                    )
                                }
                                .buttonStyle(FGCardButtonStyle())
                            }
                        }
                    }

                    // Content fields based on type
                    qrContentFields

                    // Position picker
                    VStack(alignment: .leading, spacing: FGSpacing.xs) {
                        Text("QR Position")
                            .font(FGTypography.label)
                            .foregroundColor(FGColors.textSecondary)

                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: FGSpacing.xs) {
                            ForEach(QRPosition.allCases) { position in
                                Button {
                                    qrSettings.position = position
                                } label: {
                                    HStack(spacing: FGSpacing.xs) {
                                        Image(systemName: position.icon)
                                            .font(.system(size: 16))
                                        Text(position.displayName)
                                            .font(FGTypography.label)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, FGSpacing.sm)
                                    .background(qrSettings.position == position ? FGColors.accentPrimary : FGColors.surfaceDefault)
                                    .foregroundColor(qrSettings.position == position ? FGColors.textOnAccent : FGColors.textSecondary)
                                    .clipShape(RoundedRectangle(cornerRadius: FGSpacing.buttonRadius))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: FGSpacing.buttonRadius)
                                            .stroke(qrSettings.position == position ? FGColors.accentPrimary : FGColors.borderSubtle, lineWidth: 1)
                                    )
                                }
                                .buttonStyle(FGCardButtonStyle())
                            }
                        }
                    }
                }
            }
            .padding(FGSpacing.cardPadding)
            .background(FGColors.backgroundElevated)
            .clipShape(RoundedRectangle(cornerRadius: FGSpacing.cardRadius))
            .overlay(
                RoundedRectangle(cornerRadius: FGSpacing.cardRadius)
                    .stroke(FGColors.borderSubtle, lineWidth: 1)
            )
            .padding(.horizontal, FGSpacing.screenHorizontal)
        }
    }

    @ViewBuilder
    private var qrContentFields: some View {
        switch qrSettings.contentType {
        case .url:
            FGTextField(placeholder: "https://example.com", text: $qrSettings.url.bound, icon: "link")
        case .vcard:
            VStack(spacing: FGSpacing.sm) {
                FGTextField(placeholder: "Name *", text: $qrSettings.vcardName.bound, icon: "person")
                FGTextField(placeholder: "Phone", text: $qrSettings.vcardPhone.bound, icon: "phone")
                FGTextField(placeholder: "Email", text: $qrSettings.vcardEmail.bound, icon: "envelope")
                FGTextField(placeholder: "Company", text: $qrSettings.vcardCompany.bound, icon: "building.2")
                FGTextField(placeholder: "Job Title", text: $qrSettings.vcardTitle.bound, icon: "briefcase")
                FGTextField(placeholder: "Website", text: $qrSettings.vcardWebsite.bound, icon: "globe")
            }
        case .text:
            FGTextField(placeholder: "Enter text", text: $qrSettings.text.bound, icon: "text.alignleft")
        case .email:
            VStack(spacing: FGSpacing.sm) {
                FGTextField(placeholder: "Email address *", text: $qrSettings.emailAddress.bound, icon: "envelope")
                FGTextField(placeholder: "Subject", text: $qrSettings.emailSubject.bound, icon: "text.alignleft")
            }
        case .phone:
            FGTextField(placeholder: "Phone number *", text: $qrSettings.phoneNumber.bound, icon: "phone")
        case .wifi:
            VStack(spacing: FGSpacing.sm) {
                FGTextField(placeholder: "Network Name (SSID) *", text: $qrSettings.wifiSSID.bound, icon: "wifi")
                FGTextField(placeholder: "Password", text: $qrSettings.wifiPassword.bound, icon: "lock")

                VStack(alignment: .leading, spacing: FGSpacing.xs) {
                    Text("Security")
                        .font(FGTypography.label)
                        .foregroundColor(FGColors.textSecondary)

                    Picker("Security", selection: $qrSettings.wifiSecurity.bound) {
                        Text("WPA/WPA2").tag("WPA")
                        Text("WEP").tag("WEP")
                        Text("None").tag("nopass")
                    }
                    .pickerStyle(.segmented)
                }
            }
        }
    }

    // MARK: - Actions

    private var saveButton: some View {
        Button {
            saveBrandKit()
        } label: {
            Text("Save Brand Kit")
                .font(FGTypography.button)
                .foregroundColor(FGColors.textOnAccent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, FGSpacing.md)
                .background(FGGradients.accent)
                .clipShape(RoundedRectangle(cornerRadius: FGSpacing.buttonRadius))
                .shadow(color: FGColors.accentPrimary.opacity(0.3), radius: 8, y: 4)
        }
        .buttonStyle(FGPrimaryButtonStyle())
        .padding(.horizontal, FGSpacing.screenHorizontal)
    }

    private var deleteButton: some View {
        Button {
            showingDeleteConfirmation = true
        } label: {
            Text("Delete Brand Kit")
                .font(FGTypography.button)
                .foregroundColor(FGColors.error)
                .frame(maxWidth: .infinity)
                .padding(.vertical, FGSpacing.md)
                .background(FGColors.surfaceDefault)
                .clipShape(RoundedRectangle(cornerRadius: FGSpacing.buttonRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: FGSpacing.buttonRadius)
                        .stroke(FGColors.error.opacity(0.3), lineWidth: 1)
                )
        }
        .padding(.horizontal, FGSpacing.screenHorizontal)
        .padding(.bottom, FGSpacing.lg)
    }

    // MARK: - Data Operations

    private func loadFromBrandKit() {
        guard let kit = brandKit else { return }
        logoImageData = kit.logoImageData
        logoPosition = kit.logoPosition
        businessName = kit.businessName ?? ""
        phone = kit.phone ?? ""
        email = kit.email ?? ""
        website = kit.website ?? ""
        address = kit.address ?? ""
        socialHandle = kit.socialHandle ?? ""
        qrSettings = kit.qrSettings ?? QRCodeSettings()
    }

    private func saveBrandKit() {
        let kit = brandKit ?? BrandKit()

        kit.logoImageData = logoImageData
        kit.logoPosition = logoPosition
        kit.businessName = businessName.isEmpty ? nil : businessName
        kit.phone = phone.isEmpty ? nil : phone
        kit.email = email.isEmpty ? nil : email
        kit.website = website.isEmpty ? nil : website
        kit.address = address.isEmpty ? nil : address
        kit.socialHandle = socialHandle.isEmpty ? nil : socialHandle
        kit.qrSettings = qrSettings.enabled ? qrSettings : nil
        kit.updatedAt = Date()

        if brandKit == nil {
            modelContext.insert(kit)
        }

        try? modelContext.save()
        dismiss()
    }

    private func deleteBrandKit() {
        guard let kit = brandKit else { return }
        modelContext.delete(kit)
        try? modelContext.save()
        dismiss()
    }

    private func loadLogo(from item: PhotosPickerItem?) async {
        guard let item = item else { return }
        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                logoImageData = data
            }
        } catch {
            print("Failed to load logo: \(error)")
        }
    }
}

#Preview {
    BrandKitView()
}
