import SwiftUI

struct TemplatePickerView: View {
    @ObservedObject var viewModel: FlyerCreationViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedCategory: FlyerCategory?
    @State private var selectedTemplate: FlyerTemplate?

    private var filteredTemplates: [FlyerTemplate] {
        if let category = selectedCategory {
            return TemplateLibrary.templates(for: category)
        }
        return TemplateLibrary.templates
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Category filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: FGSpacing.sm) {
                        CategoryFilterChip(
                            title: "All",
                            isSelected: selectedCategory == nil
                        ) {
                            selectedCategory = nil
                        }

                        ForEach(TemplateLibrary.availableCategories, id: \.self) { category in
                            CategoryFilterChip(
                                title: category.displayName,
                                isSelected: selectedCategory == category
                            ) {
                                selectedCategory = category
                            }
                        }
                    }
                    .padding(.horizontal, FGSpacing.screenHorizontal)
                }
                .padding(.vertical, FGSpacing.sm)
                .background(FGColors.backgroundSecondary)

                Rectangle()
                    .fill(FGColors.borderSubtle)
                    .frame(height: 1)

                // Template grid
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: FGSpacing.md),
                        GridItem(.flexible(), spacing: FGSpacing.md)
                    ], spacing: FGSpacing.md) {
                        ForEach(filteredTemplates) { template in
                            TemplateCard(template: template) {
                                selectedTemplate = template
                            }
                        }
                    }
                    .padding(FGSpacing.screenHorizontal)
                }
                .background(FGColors.backgroundPrimary)
            }
            .background(FGColors.backgroundPrimary)
            .navigationTitle("Templates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(FGColors.accentPrimary)
                }
            }
            .sheet(item: $selectedTemplate) { template in
                TemplatePreviewView(
                    template: template,
                    viewModel: viewModel,
                    onDismissParent: { dismiss() }
                )
            }
        }
    }
}

// MARK: - Category Filter Chip

private struct CategoryFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(FGTypography.label)
                .foregroundColor(isSelected ? FGColors.textOnAccent : FGColors.textPrimary)
                .padding(.horizontal, FGSpacing.md)
                .padding(.vertical, FGSpacing.sm)
                .background(isSelected ? FGColors.accentPrimary : FGColors.surfaceDefault)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? FGColors.accentPrimary : FGColors.borderSubtle, lineWidth: 1)
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
