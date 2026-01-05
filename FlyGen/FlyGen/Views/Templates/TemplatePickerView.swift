import SwiftUI

struct TemplatePickerView: View {
    @ObservedObject var viewModel: FlyerCreationViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedIntent: Intent?
    @State private var showAllTemplates: Bool = false
    @State private var selectedTemplate: FlyerTemplate?

    var body: some View {
        NavigationStack {
            if selectedIntent == nil {
                TemplateIntentSelectionContent(
                    selectedIntent: $selectedIntent,
                    onCancel: { dismiss() }
                )
            } else {
                TemplateGridContent(
                    viewModel: viewModel,
                    selectedIntent: $selectedIntent,
                    showAllTemplates: $showAllTemplates,
                    selectedTemplate: $selectedTemplate,
                    onDismiss: { dismiss() }
                )
            }
        }
    }
}

// MARK: - Step 1: Intent Selection

private struct TemplateIntentSelectionContent: View {
    @Binding var selectedIntent: Intent?
    let onCancel: () -> Void

    private let columns = [
        GridItem(.flexible(), spacing: FGSpacing.md),
        GridItem(.flexible(), spacing: FGSpacing.md)
    ]

    /// Count templates for each intent
    private func templateCount(for intent: Intent) -> Int {
        let categories = Set(intent.outputTypes.map { $0.category })
        return TemplateLibrary.templates.filter { categories.contains($0.category) }.count
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: FGSpacing.lg) {
                FGStepHeader(
                    title: "What's your goal?",
                    subtitle: "Choose what you want to achieve",
                    tooltipText: "Your goal helps us show you the most relevant templates"
                )

                LazyVGrid(columns: columns, spacing: FGSpacing.md) {
                    ForEach(Intent.allCases) { intent in
                        TemplateIntentCard(
                            intent: intent,
                            templateCount: templateCount(for: intent)
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedIntent = intent
                            }
                        }
                    }
                }
                .padding(.horizontal, FGSpacing.screenHorizontal)
            }
            .padding(.vertical, FGSpacing.lg)
        }
        .background(FGColors.backgroundPrimary)
        .navigationTitle("Templates")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    onCancel()
                }
                .foregroundColor(FGColors.accentPrimary)
            }
        }
    }
}

/// Intent selection card with emoji, title, subtitle, and template count
private struct TemplateIntentCard: View {
    let intent: Intent
    let templateCount: Int
    let action: () -> Void

    var body: some View {
        SelectionCard(isSelected: false, action: action) {
            VStack(spacing: FGSpacing.sm) {
                ZStack {
                    Circle()
                        .fill(FGColors.backgroundTertiary)
                        .frame(width: 56, height: 56)

                    Text(intent.emoji)
                        .font(.system(size: 28))
                }

                VStack(spacing: FGSpacing.xxxs) {
                    Text(intent.displayName)
                        .font(FGTypography.labelLarge)
                        .foregroundColor(FGColors.textPrimary)

                    Text(intent.subtitle)
                        .font(FGTypography.caption)
                        .foregroundColor(FGColors.textTertiary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)

                    if templateCount > 0 {
                        Text("\(templateCount) template\(templateCount == 1 ? "" : "s")")
                            .font(FGTypography.caption)
                            .foregroundColor(FGColors.textSecondary)
                            .padding(.top, FGSpacing.xxxs)
                    }
                }
            }
            .frame(height: 150)
        }
    }
}

// MARK: - Step 2: Template Grid (Filtered by Intent)

private struct TemplateGridContent: View {
    @ObservedObject var viewModel: FlyerCreationViewModel
    @Binding var selectedIntent: Intent?
    @Binding var showAllTemplates: Bool
    @Binding var selectedTemplate: FlyerTemplate?
    let onDismiss: () -> Void

    private let columns = [
        GridItem(.flexible(), spacing: FGSpacing.md),
        GridItem(.flexible(), spacing: FGSpacing.md)
    ]

    /// Templates filtered by selected intent's categories
    private var filteredTemplates: [FlyerTemplate] {
        guard let intent = selectedIntent else { return [] }

        if showAllTemplates {
            return TemplateLibrary.templates
        }

        let categories = Set(intent.outputTypes.map { $0.category })
        return TemplateLibrary.templates.filter { categories.contains($0.category) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: FGSpacing.lg) {
                // Header showing selected intent
                if let intent = selectedIntent {
                    FGStepHeader(
                        title: "\(intent.emoji) \(intent.displayName)",
                        subtitle: showAllTemplates ? "All templates" : "Templates for \(intent.subtitle.lowercased())",
                        tooltipText: "Choose a template to get started quickly"
                    )
                }

                // Template grid
                if filteredTemplates.isEmpty {
                    VStack(spacing: FGSpacing.md) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(FGColors.textTertiary)

                        Text("No templates yet")
                            .font(FGTypography.body)
                            .foregroundColor(FGColors.textSecondary)

                        Text("Try showing all templates")
                            .font(FGTypography.caption)
                            .foregroundColor(FGColors.textTertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, FGSpacing.xxxl)
                } else {
                    LazyVGrid(columns: columns, spacing: FGSpacing.md) {
                        ForEach(filteredTemplates) { template in
                            TemplateCard(template: template) {
                                selectedTemplate = template
                            }
                        }
                    }
                    .padding(.horizontal, FGSpacing.screenHorizontal)
                }

                // Show All Templates toggle
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showAllTemplates.toggle()
                    }
                } label: {
                    HStack {
                        Text(showAllTemplates ? "Show Filtered" : "Show All Templates")
                            .font(FGTypography.body)
                        Image(systemName: showAllTemplates ? "line.3.horizontal.decrease.circle" : "square.grid.2x2")
                            .font(.system(size: 14))
                    }
                    .foregroundColor(FGColors.accentPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, FGSpacing.md)
                }
                .padding(.horizontal, FGSpacing.screenHorizontal)
            }
            .padding(.vertical, FGSpacing.lg)
        }
        .background(FGColors.backgroundPrimary)
        .navigationTitle("Templates")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedIntent = nil
                        showAllTemplates = false
                    }
                } label: {
                    HStack(spacing: FGSpacing.xs) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Back")
                    }
                    .foregroundColor(FGColors.accentPrimary)
                }
            }

            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    onDismiss()
                }
                .foregroundColor(FGColors.accentPrimary)
            }
        }
        .fullScreenCover(item: $selectedTemplate) { template in
            TemplatePreviewView(
                template: template,
                viewModel: viewModel,
                onDismissParent: { onDismiss() }
            )
        }
    }
}

// MARK: - Template Card

private struct TemplateCard: View {
    let template: FlyerTemplate
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: FGSpacing.sm) {
                // Style preview area
                ZStack {
                    // Background gradient based on template colors
                    LinearGradient(
                        colors: template.colors.preset.previewColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    // Visual style indicator
                    VStack(spacing: FGSpacing.xs) {
                        Image(systemName: template.category.icon)
                            .font(.title)
                        Text(template.visuals.style.displayName)
                            .font(FGTypography.captionBold)
                    }
                    .foregroundColor(template.colors.backgroundType == .dark ? .white : .black)
                }
                .frame(height: 100)
                .clipShape(RoundedRectangle(cornerRadius: FGSpacing.inputRadius))

                // Template info
                VStack(alignment: .leading, spacing: FGSpacing.xxs) {
                    Text(template.name)
                        .font(FGTypography.labelLarge)
                        .foregroundColor(FGColors.textPrimary)
                        .lineLimit(1)

                    Text(template.category.displayName)
                        .font(FGTypography.caption)
                        .foregroundColor(FGColors.textSecondary)

                    // Color dots
                    HStack(spacing: FGSpacing.xxs) {
                        ForEach(template.colors.preset.previewColors.prefix(4), id: \.self) { color in
                            Circle()
                                .fill(color)
                                .frame(width: 12, height: 12)
                        }
                    }
                    .padding(.top, FGSpacing.xxs)
                }
                .padding(.horizontal, FGSpacing.xxs)
            }
            .padding(FGSpacing.sm)
            .background(FGColors.backgroundElevated)
            .clipShape(RoundedRectangle(cornerRadius: FGSpacing.cardRadius))
            .overlay(
                RoundedRectangle(cornerRadius: FGSpacing.cardRadius)
                    .stroke(FGColors.borderSubtle, lineWidth: 1)
            )
        }
    }
}

// MARK: - Preview

#Preview {
    TemplatePickerView(viewModel: FlyerCreationViewModel())
}
