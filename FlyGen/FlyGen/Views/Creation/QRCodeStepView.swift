import SwiftUI
import PhotosUI

struct QRCodeStepView: View {
    @ObservedObject var viewModel: FlyerCreationViewModel

    private var qrSettings: Binding<QRCodeSettings> {
        Binding(
            get: { viewModel.project?.qrSettings ?? QRCodeSettings() },
            set: { viewModel.project?.qrSettings = $0 }
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: FGSpacing.lg) {
                // Header
                FGStepHeader(
                    title: "Logo & QR Code",
                    subtitle: "Add your logo and a scannable QR code",
                    tooltipText: "Logo and QR codes help brand your flyer and provide quick access to information"
                )

                // Enable toggle
                VStack(spacing: FGSpacing.md) {
                    Toggle(isOn: qrSettings.enabled) {
                        HStack(spacing: FGSpacing.sm) {
                            Image(systemName: "qrcode")
                                .font(.system(size: 20))
                                .foregroundColor(FGColors.accentPrimary)

                            Text("Include QR Code")
                                .font(FGTypography.labelLarge)
                                .foregroundColor(FGColors.textPrimary)
                        }
                    }
                    .tint(FGColors.accentPrimary)
                    .padding(FGSpacing.cardPadding)
                    .background(FGColors.surfaceDefault)
                    .clipShape(RoundedRectangle(cornerRadius: FGSpacing.cardRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: FGSpacing.cardRadius)
                            .stroke(FGColors.borderSubtle, lineWidth: 1)
                    )
                }
                .padding(.horizontal, FGSpacing.screenHorizontal)

                if qrSettings.wrappedValue.enabled {
                    // Content type picker
                    contentTypePicker
                        .padding(.horizontal, FGSpacing.screenHorizontal)

                    // Content fields
                    contentFieldsView
                        .padding(.horizontal, FGSpacing.screenHorizontal)

                    // Divider
                    Rectangle()
                        .fill(FGColors.borderSubtle)
                        .frame(height: 1)
                        .padding(.horizontal, FGSpacing.screenHorizontal)

                    // Position picker
                    positionPicker
                        .padding(.horizontal, FGSpacing.screenHorizontal)

                    // Preview
                    previewSection
                        .padding(.horizontal, FGSpacing.screenHorizontal)
                }

                // Divider before logo section
                Rectangle()
                    .fill(FGColors.borderSubtle)
                    .frame(height: 1)
                    .padding(.horizontal, FGSpacing.screenHorizontal)

                // Logo section
                logoSection
                    .padding(.horizontal, FGSpacing.screenHorizontal)
            }
            .padding(.vertical, FGSpacing.lg)
        }
        .background(FGColors.backgroundPrimary)
        .scrollDismissesKeyboard(.interactively)
    }

    // MARK: - Logo Section

    private var logoSection: some View {
        VStack(alignment: .leading, spacing: FGSpacing.md) {
            HStack {
                Text("Logo")
                    .font(FGTypography.h3)
                    .foregroundColor(FGColors.textPrimary)

                FGInfoBadge(text: "Optional")
            }

            if let logoData = viewModel.project?.logoImageData,
               let uiImage = UIImage(data: logoData) {
                // Show uploaded logo with position picker
                uploadedLogoView(uiImage)
            } else {
                // Show upload button
                logoUploadButton
            }
        }
    }

    private func uploadedLogoView(_ image: UIImage) -> some View {
        VStack(spacing: FGSpacing.md) {
            HStack(spacing: FGSpacing.md) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: FGSpacing.inputRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: FGSpacing.inputRadius)
                            .stroke(FGColors.borderSubtle, lineWidth: 1)
                    )

                VStack(alignment: .leading, spacing: FGSpacing.xxs) {
                    Text("Logo uploaded")
                        .font(FGTypography.label)
                        .foregroundColor(FGColors.textPrimary)

                    Text("Will be placed on your flyer")
                        .font(FGTypography.caption)
                        .foregroundColor(FGColors.textTertiary)
                }

                Spacer()

                Button {
                    withAnimation(FGAnimations.spring) {
                        viewModel.clearLogo()
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(FGColors.statusError)
                }
            }
            .padding(FGSpacing.cardPadding)
            .background(FGColors.surfaceDefault)
            .clipShape(RoundedRectangle(cornerRadius: FGSpacing.cardRadius))
            .overlay(
                RoundedRectangle(cornerRadius: FGSpacing.cardRadius)
                    .stroke(FGColors.borderSubtle, lineWidth: 1)
            )

            // Logo position picker
            logoPositionPicker
        }
    }

    private var logoUploadButton: some View {
        PhotosPicker(selection: $viewModel.selectedLogoItem, matching: .images) {
            HStack(spacing: FGSpacing.sm) {
                ZStack {
                    RoundedRectangle(cornerRadius: FGSpacing.inputRadius)
                        .fill(FGColors.backgroundTertiary)
                        .frame(width: 48, height: 48)

                    Image(systemName: "photo.badge.plus")
                        .font(.system(size: 20))
                        .foregroundColor(FGColors.accentPrimary)
                }

                VStack(alignment: .leading, spacing: FGSpacing.xxs) {
                    Text("Add Your Logo")
                        .font(FGTypography.labelLarge)
                        .foregroundColor(FGColors.textPrimary)

                    Text("PNG or JPG, transparent background works best")
                        .font(FGTypography.caption)
                        .foregroundColor(FGColors.textTertiary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(FGColors.textTertiary)
            }
            .padding(FGSpacing.cardPadding)
            .background(FGColors.surfaceDefault)
            .clipShape(RoundedRectangle(cornerRadius: FGSpacing.cardRadius))
            .overlay(
                RoundedRectangle(cornerRadius: FGSpacing.cardRadius)
                    .stroke(FGColors.borderSubtle, lineWidth: 1)
            )
        }
        .onChange(of: viewModel.selectedLogoItem) { _, _ in
            Task {
                await viewModel.loadLogo()
            }
        }
    }

    private var logoPositionPicker: some View {
        VStack(alignment: .leading, spacing: FGSpacing.sm) {
            Text("Logo Position")
                .font(FGTypography.label)
                .foregroundColor(FGColors.textSecondary)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: FGSpacing.sm),
                GridItem(.flexible(), spacing: FGSpacing.sm)
            ], spacing: FGSpacing.sm) {
                ForEach(LogoPosition.allCases) { position in
                    LogoPositionButton(
                        position: position,
                        isSelected: viewModel.project?.logoPosition == position
                    ) {
                        withAnimation(FGAnimations.spring) {
                            viewModel.project?.logoPosition = position
                        }
                    }
                }
            }
        }
    }

    // MARK: - Content Type Picker

    private var contentTypePicker: some View {
        VStack(alignment: .leading, spacing: FGSpacing.sm) {
            Text("QR Code Content")
                .font(FGTypography.h3)
                .foregroundColor(FGColors.textPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: FGSpacing.sm) {
                    ForEach(QRContentType.allCases) { type in
                        ContentTypeButton(
                            type: type,
                            isSelected: qrSettings.wrappedValue.contentType == type
                        ) {
                            withAnimation(FGAnimations.spring) {
                                qrSettings.wrappedValue.contentType = type
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Content Fields

    @ViewBuilder
    private var contentFieldsView: some View {
        VStack(alignment: .leading, spacing: FGSpacing.md) {
            switch qrSettings.wrappedValue.contentType {
            case .url:
                FGTextField(placeholder: "https://example.com", text: qrSettings.url.bound, icon: "link")

            case .vcard:
                VCardFieldsView(settings: qrSettings)

            case .text:
                FGTextField(placeholder: "Enter text message", text: qrSettings.text.bound, icon: "text.alignleft")

            case .email:
                FGTextField(placeholder: "email@example.com", text: qrSettings.emailAddress.bound, icon: "envelope")
                FGTextField(placeholder: "Subject (optional)", text: qrSettings.emailSubject.bound)

            case .phone:
                FGTextField(placeholder: "+1 555 123 4567", text: qrSettings.phoneNumber.bound, icon: "phone")

            case .wifi:
                WiFiFieldsView(settings: qrSettings)
            }
        }
    }

    // MARK: - Position Picker

    private var positionPicker: some View {
        VStack(alignment: .leading, spacing: FGSpacing.md) {
            Text("Position")
                .font(FGTypography.h3)
                .foregroundColor(FGColors.textPrimary)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: FGSpacing.sm),
                GridItem(.flexible(), spacing: FGSpacing.sm)
            ], spacing: FGSpacing.sm) {
                ForEach(QRPosition.allCases) { position in
                    PositionButton(
                        position: position,
                        isSelected: qrSettings.wrappedValue.position == position
                    ) {
                        withAnimation(FGAnimations.spring) {
                            qrSettings.wrappedValue.position = position
                        }
                    }
                }
            }
        }
    }

    // MARK: - Preview Section

    @ViewBuilder
    private var previewSection: some View {
        if qrSettings.wrappedValue.hasValidContent {
            VStack(alignment: .leading, spacing: FGSpacing.sm) {
                Text("Preview")
                    .font(FGTypography.h3)
                    .foregroundColor(FGColors.textPrimary)

                QRPreviewView(settings: qrSettings.wrappedValue)
            }
        }
    }
}

// MARK: - Content Type Button

struct ContentTypeButton: View {
    let type: QRContentType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: FGSpacing.xxs) {
                Image(systemName: type.icon)
                    .font(.system(size: 20, weight: .medium))
                Text(type.displayName)
                    .font(FGTypography.captionBold)
                    .lineLimit(1)
            }
            .frame(width: 80, height: 64)
            .background(isSelected ? FGColors.accentPrimary : FGColors.surfaceDefault)
            .foregroundColor(isSelected ? FGColors.textOnAccent : FGColors.textSecondary)
            .clipShape(RoundedRectangle(cornerRadius: FGSpacing.cardRadius))
            .overlay(
                RoundedRectangle(cornerRadius: FGSpacing.cardRadius)
                    .stroke(isSelected ? FGColors.accentPrimary : FGColors.borderSubtle, lineWidth: 1)
            )
        }
        .buttonStyle(FGCardButtonStyle())
    }
}

// MARK: - Position Button

struct PositionButton: View {
    let position: QRPosition
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: FGSpacing.xs) {
                Image(systemName: position.icon)
                    .font(.system(size: 16))
                Text(position.displayName)
                    .font(FGTypography.label)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, FGSpacing.sm)
            .background(isSelected ? FGColors.accentPrimary : FGColors.surfaceDefault)
            .foregroundColor(isSelected ? FGColors.textOnAccent : FGColors.textSecondary)
            .clipShape(RoundedRectangle(cornerRadius: FGSpacing.buttonRadius))
            .overlay(
                RoundedRectangle(cornerRadius: FGSpacing.buttonRadius)
                    .stroke(isSelected ? FGColors.accentPrimary : FGColors.borderSubtle, lineWidth: 1)
            )
        }
        .buttonStyle(FGCardButtonStyle())
    }
}

// MARK: - vCard Fields View

struct VCardFieldsView: View {
    @Binding var settings: QRCodeSettings

    var body: some View {
        VStack(spacing: FGSpacing.sm) {
            FGTextField(placeholder: "Name *", text: $settings.vcardName.bound, icon: "person")
            FGTextField(placeholder: "Phone", text: $settings.vcardPhone.bound, icon: "phone")
            FGTextField(placeholder: "Email", text: $settings.vcardEmail.bound, icon: "envelope")
            FGTextField(placeholder: "Company", text: $settings.vcardCompany.bound, icon: "building.2")
            FGTextField(placeholder: "Job Title", text: $settings.vcardTitle.bound, icon: "briefcase")
            FGTextField(placeholder: "Website", text: $settings.vcardWebsite.bound, icon: "globe")
        }
    }
}

// MARK: - WiFi Fields View

struct WiFiFieldsView: View {
    @Binding var settings: QRCodeSettings

    var body: some View {
        VStack(spacing: FGSpacing.sm) {
            FGTextField(placeholder: "Network Name (SSID) *", text: $settings.wifiSSID.bound, icon: "wifi")

            // Password field
            HStack(spacing: FGSpacing.sm) {
                Image(systemName: "lock")
                    .font(.system(size: 16))
                    .foregroundColor(FGColors.textTertiary)

                SecureField("Password", text: $settings.wifiPassword.bound)
                    .font(FGTypography.body)
                    .foregroundColor(FGColors.textPrimary)
            }
            .padding(FGSpacing.sm)
            .background(FGColors.surfaceDefault)
            .clipShape(RoundedRectangle(cornerRadius: FGSpacing.inputRadius))
            .overlay(
                RoundedRectangle(cornerRadius: FGSpacing.inputRadius)
                    .stroke(FGColors.borderSubtle, lineWidth: 1)
            )

            // Security picker
            VStack(alignment: .leading, spacing: FGSpacing.xs) {
                Text("Security")
                    .font(FGTypography.label)
                    .foregroundColor(FGColors.textSecondary)

                Picker("Security", selection: $settings.wifiSecurity.bound) {
                    Text("WPA/WPA2").tag("WPA")
                    Text("WEP").tag("WEP")
                    Text("None").tag("nopass")
                }
                .pickerStyle(.segmented)
            }
        }
    }
}

// MARK: - QR Preview View

struct QRPreviewView: View {
    let settings: QRCodeSettings
    @State private var qrImage: UIImage?

    var body: some View {
        HStack {
            Group {
                if let image = qrImage {
                    Image(uiImage: image)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: FGSpacing.inputRadius))
                } else {
                    ProgressView()
                        .frame(width: 100, height: 100)
                        .background(FGColors.surfaceDefault)
                        .clipShape(RoundedRectangle(cornerRadius: FGSpacing.inputRadius))
                }
            }

            VStack(alignment: .leading, spacing: FGSpacing.xs) {
                Text("Scan to test")
                    .font(FGTypography.label)
                    .foregroundColor(FGColors.textSecondary)

                Text("This QR code will be added to your flyer")
                    .font(FGTypography.caption)
                    .foregroundColor(FGColors.textTertiary)
            }

            Spacer()
        }
        .padding(FGSpacing.cardPadding)
        .background(FGColors.surfaceDefault)
        .clipShape(RoundedRectangle(cornerRadius: FGSpacing.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: FGSpacing.cardRadius)
                .stroke(FGColors.borderSubtle, lineWidth: 1)
        )
        .task(id: settings) {
            await generatePreview()
        }
    }

    private func generatePreview() async {
        let service = QRCodeService()
        guard let content = await service.generateContent(from: settings) else {
            qrImage = nil
            return
        }
        qrImage = await service.generateQRCode(
            from: content,
            size: CGSize(width: 200, height: 200)
        )
    }
}

// MARK: - Binding Extensions

extension Binding where Value == String? {
    var bound: Binding<String> {
        Binding<String>(
            get: { self.wrappedValue ?? "" },
            set: { self.wrappedValue = $0.isEmpty ? nil : $0 }
        )
    }
}

// MARK: - Logo Position Button

struct LogoPositionButton: View {
    let position: LogoPosition
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: FGSpacing.xs) {
                Image(systemName: position.icon)
                    .font(.system(size: 16))
                Text(position.displayName)
                    .font(FGTypography.label)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, FGSpacing.sm)
            .background(isSelected ? FGColors.accentPrimary : FGColors.surfaceDefault)
            .foregroundColor(isSelected ? FGColors.textOnAccent : FGColors.textSecondary)
            .clipShape(RoundedRectangle(cornerRadius: FGSpacing.buttonRadius))
            .overlay(
                RoundedRectangle(cornerRadius: FGSpacing.buttonRadius)
                    .stroke(isSelected ? FGColors.accentPrimary : FGColors.borderSubtle, lineWidth: 1)
            )
        }
        .buttonStyle(FGCardButtonStyle())
    }
}

#Preview {
    let vm = FlyerCreationViewModel()
    vm.startNewFlyer(category: .event)
    return QRCodeStepView(viewModel: vm)
}
