import SwiftUI

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
            VStack(alignment: .leading, spacing: 24) {
                // Enable toggle
                Toggle(isOn: qrSettings.enabled) {
                    Label("Add QR Code", systemImage: "qrcode")
                        .font(.headline)
                }
                .tint(.accentColor)

                if qrSettings.wrappedValue.enabled {
                    // Content type picker
                    contentTypePicker

                    // Content fields
                    contentFieldsView

                    Divider()

                    // Position picker
                    positionPicker

                    // Preview
                    previewSection
                }
            }
            .padding()
        }
        .scrollDismissesKeyboard(.interactively)
    }

    // MARK: - Content Type Picker

    private var contentTypePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("QR Code Content")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(QRContentType.allCases) { type in
                        ContentTypeButton(
                            type: type,
                            isSelected: qrSettings.wrappedValue.contentType == type
                        ) {
                            qrSettings.wrappedValue.contentType = type
                        }
                    }
                }
            }
        }
    }

    // MARK: - Content Fields

    @ViewBuilder
    private var contentFieldsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            switch qrSettings.wrappedValue.contentType {
            case .url:
                TextField("https://example.com", text: qrSettings.url.bound)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

            case .vcard:
                VCardFieldsView(settings: qrSettings)

            case .text:
                TextField("Enter text message", text: qrSettings.text.bound)
                    .textFieldStyle(.roundedBorder)

            case .email:
                TextField("email@example.com", text: qrSettings.emailAddress.bound)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)

                TextField("Subject (optional)", text: qrSettings.emailSubject.bound)
                    .textFieldStyle(.roundedBorder)

            case .phone:
                TextField("+1 555 123 4567", text: qrSettings.phoneNumber.bound)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.phonePad)

            case .wifi:
                WiFiFieldsView(settings: qrSettings)
            }
        }
    }

    // MARK: - Position Picker

    private var positionPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Position")
                .font(.headline)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(QRPosition.allCases) { position in
                    PositionButton(
                        position: position,
                        isSelected: qrSettings.wrappedValue.position == position
                    ) {
                        qrSettings.wrappedValue.position = position
                    }
                }
            }
        }
    }

    // MARK: - Preview Section

    @ViewBuilder
    private var previewSection: some View {
        if qrSettings.wrappedValue.hasValidContent {
            VStack(alignment: .leading, spacing: 8) {
                Text("Preview")
                    .font(.headline)

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
            VStack(spacing: 4) {
                Image(systemName: type.icon)
                    .font(.title2)
                Text(type.displayName)
                    .font(.caption)
                    .lineLimit(1)
            }
            .frame(width: 80, height: 60)
            .background(isSelected ? Color.accentColor : Color(.systemGray6))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(8)
        }
    }
}

// MARK: - Position Button

struct PositionButton: View {
    let position: QRPosition
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: position.icon)
                Text(position.displayName)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? Color.accentColor : Color(.systemGray6))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(8)
        }
    }
}

// MARK: - vCard Fields View

struct VCardFieldsView: View {
    @Binding var settings: QRCodeSettings

    var body: some View {
        VStack(spacing: 12) {
            TextField("Name *", text: $settings.vcardName.bound)
                .textFieldStyle(.roundedBorder)

            TextField("Phone", text: $settings.vcardPhone.bound)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.phonePad)

            TextField("Email", text: $settings.vcardEmail.bound)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)

            TextField("Company", text: $settings.vcardCompany.bound)
                .textFieldStyle(.roundedBorder)

            TextField("Job Title", text: $settings.vcardTitle.bound)
                .textFieldStyle(.roundedBorder)

            TextField("Website", text: $settings.vcardWebsite.bound)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
        }
    }
}

// MARK: - WiFi Fields View

struct WiFiFieldsView: View {
    @Binding var settings: QRCodeSettings

    var body: some View {
        VStack(spacing: 12) {
            TextField("Network Name (SSID) *", text: $settings.wifiSSID.bound)
                .textFieldStyle(.roundedBorder)

            SecureField("Password", text: $settings.wifiPassword.bound)
                .textFieldStyle(.roundedBorder)

            Picker("Security", selection: $settings.wifiSecurity.bound) {
                Text("WPA/WPA2").tag("WPA")
                Text("WEP").tag("WEP")
                Text("None").tag("nopass")
            }
            .pickerStyle(.segmented)
        }
    }
}

// MARK: - QR Preview View

struct QRPreviewView: View {
    let settings: QRCodeSettings
    @State private var qrImage: UIImage?

    var body: some View {
        Group {
            if let image = qrImage {
                Image(uiImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .background(Color.white)
                    .cornerRadius(8)
            } else {
                ProgressView()
                    .frame(width: 100, height: 100)
            }
        }
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

#Preview {
    let vm = FlyerCreationViewModel()
    vm.startNewFlyer(category: .event)
    return QRCodeStepView(viewModel: vm)
}
