import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("openrouter_api_key") private var apiKey: String = ""
    @State private var editedKey: String = ""
    @State private var showingKey = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: FGSpacing.lg) {
                    // API Configuration Section
                    apiConfigSection

                    // Generation Settings Section
                    generationSettingsSection

                    // About Section
                    aboutSection
                }
                .padding(.vertical, FGSpacing.lg)
            }
            .background(FGColors.backgroundPrimary)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(FGColors.accentPrimary)
                }
            }
            .onAppear {
                editedKey = apiKey
            }
        }
    }

    // MARK: - API Configuration Section

    private var apiConfigSection: some View {
        VStack(alignment: .leading, spacing: FGSpacing.sm) {
            Text("API Configuration")
                .font(FGTypography.h4)
                .foregroundColor(FGColors.textSecondary)
                .padding(.horizontal, FGSpacing.screenHorizontal)

            VStack(alignment: .leading, spacing: FGSpacing.md) {
                VStack(alignment: .leading, spacing: FGSpacing.sm) {
                    Text("OpenRouter API Key")
                        .font(FGTypography.label)
                        .foregroundColor(FGColors.textSecondary)

                    HStack(spacing: FGSpacing.sm) {
                        if showingKey {
                            TextField("sk-or-...", text: $editedKey)
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(FGColors.textPrimary)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                        } else {
                            SecureField("sk-or-...", text: $editedKey)
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(FGColors.textPrimary)
                        }

                        Button {
                            showingKey.toggle()
                        } label: {
                            Image(systemName: showingKey ? "eye.slash" : "eye")
                                .foregroundColor(FGColors.textSecondary)
                        }
                    }
                    .padding(FGSpacing.sm)
                    .background(FGColors.surfaceDefault)
                    .clipShape(RoundedRectangle(cornerRadius: FGSpacing.inputRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: FGSpacing.inputRadius)
                            .stroke(FGColors.borderSubtle, lineWidth: 1)
                    )
                }

                if editedKey != apiKey {
                    Button {
                        apiKey = editedKey
                    } label: {
                        Text("Save")
                            .font(FGTypography.button)
                            .foregroundColor(FGColors.textOnAccent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, FGSpacing.sm)
                            .background(FGColors.accentPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: FGSpacing.buttonRadius))
                    }
                }

                // Help text
                VStack(alignment: .leading, spacing: FGSpacing.xs) {
                    Text("Get your API key from openrouter.ai")
                        .font(FGTypography.caption)
                        .foregroundColor(FGColors.textTertiary)

                    Link(destination: URL(string: "https://openrouter.ai/keys")!) {
                        HStack(spacing: FGSpacing.xs) {
                            Text("Open OpenRouter")
                                .font(FGTypography.label)
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                        }
                        .foregroundColor(FGColors.accentPrimary)
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

    // MARK: - Generation Settings Section

    private var generationSettingsSection: some View {
        VStack(alignment: .leading, spacing: FGSpacing.sm) {
            Text("Generation Settings")
                .font(FGTypography.h4)
                .foregroundColor(FGColors.textSecondary)
                .padding(.horizontal, FGSpacing.screenHorizontal)

            VStack(spacing: 0) {
                HStack {
                    Text("Model")
                        .font(FGTypography.body)
                        .foregroundColor(FGColors.textPrimary)
                    Spacer()
                    Text("Gemini Flash")
                        .font(FGTypography.label)
                        .foregroundColor(FGColors.textSecondary)
                }
                .padding(FGSpacing.cardPadding)

                Divider()
                    .background(FGColors.borderSubtle)

                HStack {
                    Text("Provider")
                        .font(FGTypography.body)
                        .foregroundColor(FGColors.textPrimary)
                    Spacer()
                    Text("OpenRouter")
                        .font(FGTypography.label)
                        .foregroundColor(FGColors.textSecondary)
                }
                .padding(FGSpacing.cardPadding)
            }
            .background(FGColors.backgroundElevated)
            .clipShape(RoundedRectangle(cornerRadius: FGSpacing.cardRadius))
            .overlay(
                RoundedRectangle(cornerRadius: FGSpacing.cardRadius)
                    .stroke(FGColors.borderSubtle, lineWidth: 1)
            )
            .padding(.horizontal, FGSpacing.screenHorizontal)
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: FGSpacing.sm) {
            Text("About")
                .font(FGTypography.h4)
                .foregroundColor(FGColors.textSecondary)
                .padding(.horizontal, FGSpacing.screenHorizontal)

            HStack {
                Text("Version")
                    .font(FGTypography.body)
                    .foregroundColor(FGColors.textPrimary)
                Spacer()
                Text("1.0.0")
                    .font(FGTypography.label)
                    .foregroundColor(FGColors.textSecondary)
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
}

#Preview {
    SettingsView()
}
