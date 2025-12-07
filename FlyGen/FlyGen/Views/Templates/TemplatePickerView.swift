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
                    HStack(spacing: 12) {
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
                    .padding(.horizontal)
                }
                .padding(.vertical, 12)
                .background(Color(.systemBackground))

                Divider()

                // Template grid
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)
                    ], spacing: 16) {
                        ForEach(filteredTemplates) { template in
                            TemplateCard(template: template) {
                                selectedTemplate = template
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Templates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
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
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor : Color(.systemGray5))
                .cornerRadius(20)
        }
    }
}

// MARK: - Template Card

private struct TemplateCard: View {
    let template: FlyerTemplate
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                // Style preview area
                ZStack {
                    // Background gradient based on template colors
                    LinearGradient(
                        colors: template.colors.preset.previewColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    // Visual style indicator
                    VStack(spacing: 4) {
                        Image(systemName: template.category.icon)
                            .font(.title)
                        Text(template.visuals.style.displayName)
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(template.colors.backgroundType == .dark ? .white : .primary)
                }
                .frame(height: 100)
                .cornerRadius(8)

                // Template info
                VStack(alignment: .leading, spacing: 4) {
                    Text(template.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Text(template.category.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    // Color dots
                    HStack(spacing: 4) {
                        ForEach(template.colors.preset.previewColors.prefix(4), id: \.self) { color in
                            Circle()
                                .fill(color)
                                .frame(width: 12, height: 12)
                        }
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, 4)
            }
            .padding(12)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
        }
    }
}

// MARK: - Preview

#Preview {
    TemplatePickerView(viewModel: FlyerCreationViewModel())
}
