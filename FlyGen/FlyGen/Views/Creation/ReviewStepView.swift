import SwiftUI

struct ReviewStepView: View {
    @ObservedObject var viewModel: FlyerCreationViewModel

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: FGSpacing.lg) {
                    // Header
                    FGStepHeader(
                        title: "Review & Generate",
                        subtitle: "Check your choices before creating your flyer",
                        tooltipText: "You can tap Edit on any section to make changes"
                    )

                    // Summary sections
                    if let project = viewModel.project {
                        VStack(spacing: FGSpacing.sm) {
                            ReviewSection(title: "Category", icon: project.category.icon) {
                                HStack(spacing: FGSpacing.sm) {
                                    Text(project.category.emoji)
                                        .font(.system(size: 20))
                                    Text(project.category.displayName)
                                        .font(FGTypography.body)
                                        .foregroundColor(FGColors.textPrimary)
                                }
                            } editAction: {
                                viewModel.goToStep(.category)
                            }

                            ReviewSection(title: "Text Content", icon: "text.alignleft") {
                                VStack(alignment: .leading, spacing: FGSpacing.xxs) {
                                    Text(project.textContent.headline)
                                        .font(FGTypography.labelLarge)
                                        .foregroundColor(FGColors.textPrimary)

                                    if let sub = project.textContent.subheadline {
                                        Text(sub)
                                            .font(FGTypography.bodySmall)
                                            .foregroundColor(FGColors.textSecondary)
                                    }
                                }
                            } editAction: {
                                viewModel.goToStep(.textContent)
                            }

                            ReviewSection(title: "Visual Style", icon: project.visuals.style.icon) {
                                HStack(spacing: FGSpacing.xs) {
                                    Text(project.visuals.style.displayName)
                                        .font(FGTypography.body)
                                        .foregroundColor(FGColors.textPrimary)

                                    // Style tag
                                    Text(project.visuals.style.characteristics.first ?? "")
                                        .font(FGTypography.captionBold)
                                        .foregroundColor(FGColors.accentPrimary)
                                        .padding(.horizontal, FGSpacing.xs)
                                        .padding(.vertical, FGSpacing.xxxs)
                                        .background(FGColors.accentPrimary.opacity(0.15))
                                        .clipShape(Capsule())
                                }
                            } editAction: {
                                viewModel.goToStep(.visualStyle)
                            }

                            ReviewSection(title: "Mood", icon: project.visuals.mood.icon) {
                                HStack(spacing: FGSpacing.sm) {
                                    Circle()
                                        .fill(FGGradients.moodGradient(for: project.visuals.mood.rawValue))
                                        .frame(width: 24, height: 24)

                                    Text(project.visuals.mood.displayName)
                                        .font(FGTypography.body)
                                        .foregroundColor(FGColors.textPrimary)
                                }
                            } editAction: {
                                viewModel.goToStep(.mood)
                            }

                            ReviewSection(title: "Colors", icon: "paintpalette") {
                                HStack(spacing: FGSpacing.sm) {
                                    // Color swatches
                                    HStack(spacing: -6) {
                                        ForEach(project.colors.preset.previewColors.indices, id: \.self) { i in
                                            Circle()
                                                .fill(project.colors.preset.previewColors[i])
                                                .frame(width: 24, height: 24)
                                                .overlay(
                                                    Circle()
                                                        .stroke(FGColors.backgroundPrimary, lineWidth: 2)
                                                )
                                        }
                                    }

                                    Text(project.colors.preset.displayName)
                                        .font(FGTypography.body)
                                        .foregroundColor(FGColors.textPrimary)

                                    Text("•")
                                        .foregroundColor(FGColors.textTertiary)

                                    Text(project.colors.backgroundType.displayName)
                                        .font(FGTypography.bodySmall)
                                        .foregroundColor(FGColors.textSecondary)
                                }
                            } editAction: {
                                viewModel.goToStep(.colors)
                            }

                            ReviewSection(title: "Format", icon: project.output.aspectRatio.icon) {
                                HStack(spacing: FGSpacing.sm) {
                                    // Mini aspect ratio preview
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(FGColors.backgroundTertiary)
                                        .aspectRatio(project.output.aspectRatio.aspectValue, contentMode: .fit)
                                        .frame(height: 28)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 4)
                                                .stroke(FGColors.borderSubtle, lineWidth: 1)
                                        )

                                    Text(project.output.aspectRatio.displayName)
                                        .font(FGTypography.body)
                                        .foregroundColor(FGColors.textPrimary)

                                    Text("•")
                                        .foregroundColor(FGColors.textTertiary)

                                    Text(project.visuals.imageryType == .illustrated ? "AI Text" : "Text-Free")
                                        .font(FGTypography.bodySmall)
                                        .foregroundColor(FGColors.textSecondary)
                                }
                            } editAction: {
                                viewModel.goToStep(.format)
                            }

                            // QR Code section (if enabled)
                            if project.qrSettings.enabled {
                                ReviewSection(title: "QR Code", icon: "qrcode") {
                                    HStack(spacing: FGSpacing.sm) {
                                        Image(systemName: project.qrSettings.contentType.icon)
                                            .font(.system(size: 16))
                                            .foregroundColor(FGColors.accentSecondary)

                                        Text(project.qrSettings.contentType.displayName)
                                            .font(FGTypography.body)
                                            .foregroundColor(FGColors.textPrimary)

                                        Text("•")
                                            .foregroundColor(FGColors.textTertiary)

                                        Text(project.qrSettings.position.displayName)
                                            .font(FGTypography.bodySmall)
                                            .foregroundColor(FGColors.textSecondary)
                                    }
                                } editAction: {
                                    viewModel.goToStep(.qrCode)
                                }
                            }

                            // Extras section (if any)
                            if !project.visuals.includeElements.isEmpty || project.logoImageData != nil || project.targetAudience != nil {
                                ReviewSection(title: "Extras", icon: "sparkles") {
                                    VStack(alignment: .leading, spacing: FGSpacing.xs) {
                                        if !project.visuals.includeElements.isEmpty {
                                            HStack(spacing: FGSpacing.xxs) {
                                                Image(systemName: "plus.circle.fill")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(FGColors.statusSuccess)
                                                Text(project.visuals.includeElements.joined(separator: ", "))
                                                    .font(FGTypography.bodySmall)
                                                    .foregroundColor(FGColors.textSecondary)
                                            }
                                        }

                                        if let audience = project.targetAudience {
                                            HStack(spacing: FGSpacing.xxs) {
                                                Image(systemName: "person.2.fill")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(FGColors.accentSecondary)
                                                Text(audience)
                                                    .font(FGTypography.bodySmall)
                                                    .foregroundColor(FGColors.textSecondary)
                                            }
                                        }

                                        if project.logoImageData != nil {
                                            HStack(spacing: FGSpacing.xxs) {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(FGColors.statusSuccess)
                                                Text("Logo included")
                                                    .font(FGTypography.bodySmall)
                                                    .foregroundColor(FGColors.textSecondary)
                                            }
                                        }
                                    }
                                } editAction: {
                                    viewModel.goToStep(.extras)
                                }
                            }
                        }
                        .padding(.horizontal, FGSpacing.screenHorizontal)
                    }
                }
                .padding(.vertical, FGSpacing.lg)
            }

            // Generate button area
            generateButtonSection
        }
        .background(FGColors.backgroundPrimary)
    }

    // MARK: - Generate Button Section

    private var generateButtonSection: some View {
        VStack(spacing: FGSpacing.sm) {
            Button {
                Task {
                    await viewModel.generateFlyer()
                }
            } label: {
                HStack(spacing: FGSpacing.sm) {
                    if viewModel.generationState == .generating {
                        ProgressView()
                            .tint(FGColors.textOnAccent)
                    } else {
                        Image(systemName: "sparkles")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    Text(viewModel.generationState == .generating ? "Creating Magic..." : "Generate Flyer")
                        .font(FGTypography.buttonLarge)
                }
                .foregroundColor(FGColors.textOnAccent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, FGSpacing.md)
                .background(FGGradients.accent)
                .clipShape(RoundedRectangle(cornerRadius: FGSpacing.buttonRadius))
                .shadow(
                    color: FGColors.accentPrimary.opacity(0.4),
                    radius: 12,
                    y: 4
                )
            }
            .disabled(viewModel.generationState == .generating)
            .animation(FGAnimations.spring, value: viewModel.generationState)

            if case .error(let message) = viewModel.generationState {
                HStack(spacing: FGSpacing.xs) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(FGColors.statusError)

                    Text(message)
                        .font(FGTypography.caption)
                        .foregroundColor(FGColors.statusError)
                        .multilineTextAlignment(.center)
                }
                .padding(FGSpacing.sm)
                .background(FGColors.statusError.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: FGSpacing.inputRadius))
            }
        }
        .padding(FGSpacing.screenHorizontal)
        .padding(.vertical, FGSpacing.md)
        .background(
            FGColors.surfaceDefault
                .shadow(color: .black.opacity(0.2), radius: 12, y: -4)
        )
    }
}

// MARK: - Review Section Component

struct ReviewSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: () -> Content
    let editAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: FGSpacing.sm) {
            HStack {
                HStack(spacing: FGSpacing.xs) {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(FGColors.accentPrimary)
                        .frame(width: 20)

                    Text(title)
                        .font(FGTypography.label)
                        .foregroundColor(FGColors.textTertiary)
                }

                Spacer()

                Button {
                    editAction()
                } label: {
                    HStack(spacing: FGSpacing.xxs) {
                        Image(systemName: "pencil")
                            .font(.system(size: 12))
                        Text("Edit")
                            .font(FGTypography.captionBold)
                    }
                    .foregroundColor(FGColors.accentPrimary)
                    .padding(.horizontal, FGSpacing.sm)
                    .padding(.vertical, FGSpacing.xxs)
                    .background(FGColors.accentPrimary.opacity(0.15))
                    .clipShape(Capsule())
                }
            }

            content()
                .padding(.leading, FGSpacing.lg + FGSpacing.xs)
        }
        .padding(FGSpacing.cardPadding)
        .background(FGColors.surfaceDefault)
        .clipShape(RoundedRectangle(cornerRadius: FGSpacing.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: FGSpacing.cardRadius)
                .stroke(FGColors.borderSubtle, lineWidth: 1)
        )
    }
}

#Preview {
    let vm = FlyerCreationViewModel()
    vm.startNewFlyer(category: .salePromo)
    vm.project?.textContent.headline = "MEGA SUMMER SALE"
    vm.project?.textContent.subheadline = "Up to 70% off everything"
    return ReviewStepView(viewModel: vm)
}
