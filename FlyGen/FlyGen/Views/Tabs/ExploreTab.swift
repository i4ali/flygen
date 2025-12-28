import SwiftUI
import SwiftData

struct ExploreTab: View {
    @ObservedObject var viewModel: FlyerCreationViewModel
    @Query private var userProfiles: [UserProfile]
    @State private var selectedSample: SampleFlyer?
    @State private var selectedCategory: FlyerCategory? = nil  // nil = "All"

    private let columns = [
        GridItem(.adaptive(minimum: 170), spacing: FGSpacing.md)
    ]

    /// Get unique categories that have samples, sorted alphabetically
    private var availableCategories: [FlyerCategory] {
        Array(Set(SampleLibrary.samples.map { $0.category })).sorted { $0.displayName < $1.displayName }
    }

    /// Filter samples based on selected category
    private var filteredSamples: [SampleFlyer] {
        if let category = selectedCategory {
            return SampleLibrary.samples.filter { $0.category == category }
        }
        return SampleLibrary.samples
    }

    /// Check if a sample's category matches user's preferred categories
    private func isPreferredSample(_ sample: SampleFlyer) -> Bool {
        guard let preferredCategories = userProfiles.first?.preferredFlyerCategories else {
            return false
        }
        return preferredCategories.contains(sample.category)
    }

    var body: some View {
        NavigationStack {
            Group {
                if SampleLibrary.samples.isEmpty {
                    emptyState
                } else {
                    sampleGrid
                }
            }
            .background(FGColors.backgroundPrimary)
            .navigationTitle("Explore")
            .fullScreenCover(item: $selectedSample) { sample in
                SampleDetailSheet(sample: sample) {
                    selectedSample = nil
                    viewModel.loadFromSample(sample)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: FGSpacing.lg) {
            ZStack {
                Circle()
                    .fill(FGColors.accentSecondary.opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: "sparkles")
                    .font(.system(size: 50))
                    .foregroundColor(FGColors.accentSecondary)
            }

            VStack(spacing: FGSpacing.sm) {
                Text("Coming Soon")
                    .font(FGTypography.h2)
                    .foregroundColor(FGColors.textPrimary)

                Text("Sample flyers will appear here.\nGet inspired by AI-generated designs!")
                    .font(FGTypography.body)
                    .foregroundColor(FGColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, FGSpacing.xl)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(FGColors.backgroundPrimary)
    }

    private var sampleGrid: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: FGSpacing.lg) {
                // Header description
                VStack(alignment: .leading, spacing: FGSpacing.sm) {
                    Text("Get Inspired")
                        .font(FGTypography.h3)
                        .foregroundColor(FGColors.textPrimary)

                    Text("Browse sample flyers created with FlyGen. Tap to use as a starting point.")
                        .font(FGTypography.body)
                        .foregroundColor(FGColors.textSecondary)
                }
                .padding(.horizontal, FGSpacing.screenHorizontal)

                // Category filter row
                categoryFilterRow

                // Grid
                LazyVGrid(columns: columns, spacing: FGSpacing.md) {
                    ForEach(filteredSamples) { sample in
                        SampleThumbnailView(
                            sample: sample,
                            isPreferred: isPreferredSample(sample)
                        )
                        .onTapGesture {
                            selectedSample = sample
                        }
                    }
                }
                .padding(.horizontal, FGSpacing.screenHorizontal)
            }
            .padding(.top, FGSpacing.md)
        }
        .background(FGColors.backgroundPrimary)
    }

    private var categoryFilterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: FGSpacing.sm) {
                // "All" button
                FilterPillButton(
                    title: "All",
                    icon: "square.grid.2x2",
                    isSelected: selectedCategory == nil
                ) {
                    selectedCategory = nil
                }

                // Category buttons
                ForEach(availableCategories) { category in
                    FilterPillButton(
                        title: category.displayName,
                        icon: category.icon,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal, FGSpacing.screenHorizontal)
        }
    }
}

// MARK: - Sample Thumbnail View

struct SampleThumbnailView: View {
    let sample: SampleFlyer
    var isPreferred: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: FGSpacing.sm) {
            // Image thumbnail with optional "For You" badge
            ZStack(alignment: .topLeading) {
                if let uiImage = UIImage(named: sample.imageName) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(8.5/11, contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: FGSpacing.cardRadius))
                } else {
                    // Placeholder if image not found
                    RoundedRectangle(cornerRadius: FGSpacing.cardRadius)
                        .fill(
                            LinearGradient(
                                colors: [FGColors.accentPrimary.opacity(0.3), FGColors.accentSecondary.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .aspectRatio(8.5/11, contentMode: .fit)
                        .overlay {
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundColor(FGColors.textTertiary)
                        }
                }

                // "For You" badge for preferred samples
                if isPreferred {
                    ForYouBadge()
                        .padding(FGSpacing.xs)
                }
            }

            // Info
            VStack(alignment: .leading, spacing: FGSpacing.xxs) {
                Text(sample.name)
                    .font(FGTypography.labelLarge)
                    .foregroundColor(FGColors.textPrimary)
                    .lineLimit(1)

                Text(sample.category.displayName)
                    .font(FGTypography.caption)
                    .foregroundColor(FGColors.textSecondary)
            }
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

// MARK: - For You Badge

private struct ForYouBadge: View {
    var body: some View {
        HStack(spacing: FGSpacing.xxs) {
            Image(systemName: "star.fill")
                .font(.system(size: 8))
            Text("For You")
                .font(FGTypography.captionSmall)
                .fontWeight(.semibold)
        }
        .foregroundColor(.white)
        .padding(.horizontal, FGSpacing.xs)
        .padding(.vertical, FGSpacing.xxxs + 1)
        .background(
            Capsule()
                .fill(FGColors.accentSecondary)
        )
        .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
    }
}

// MARK: - Sample Detail Sheet

struct SampleDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    let sample: SampleFlyer
    let onUseAsStartingPoint: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: FGSpacing.lg) {
                    // Full image
                    if let uiImage = UIImage(named: sample.imageName) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: FGSpacing.cardRadius))
                            .shadow(color: FGColors.accentPrimary.opacity(0.2), radius: 12)
                            .padding(.horizontal, FGSpacing.screenHorizontal)
                    }

                    // Details
                    VStack(alignment: .leading, spacing: FGSpacing.sm) {
                        HStack {
                            Text("Category")
                                .font(FGTypography.body)
                                .foregroundColor(FGColors.textSecondary)
                            Spacer()
                            Text(sample.category.displayName)
                                .font(FGTypography.labelLarge)
                                .foregroundColor(FGColors.textPrimary)
                        }

                        if sample.language != .english {
                            HStack {
                                Text("Language")
                                    .font(FGTypography.body)
                                    .foregroundColor(FGColors.textSecondary)
                                Spacer()
                                Text(sample.language.displayName)
                                    .font(FGTypography.labelLarge)
                                    .foregroundColor(FGColors.textPrimary)
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

                    // "Use as Starting Point" button
                    Button {
                        onUseAsStartingPoint()
                        dismiss()
                    } label: {
                        HStack(spacing: FGSpacing.sm) {
                            Image(systemName: "wand.and.stars")
                            Text("Use as Starting Point")
                        }
                        .font(FGTypography.button)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, FGSpacing.md)
                        .background(FGColors.accentPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: FGSpacing.buttonRadius))
                    }
                    .padding(.horizontal, FGSpacing.screenHorizontal)

                    // Info text
                    Text("This sample was created using FlyGen's AI-powered flyer generator. Use it as a starting point to create your own!")
                        .font(FGTypography.caption)
                        .foregroundColor(FGColors.textTertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, FGSpacing.xl)
                }
                .padding(.vertical, FGSpacing.lg)
            }
            .background(FGColors.backgroundPrimary)
            .navigationTitle(sample.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(FGColors.textTertiary)
                    }
                }
            }
        }
    }
}

// MARK: - Filter Pill Button

struct FilterPillButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: FGSpacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                Text(title)
                    .font(FGTypography.labelSmall)
            }
            .padding(.horizontal, FGSpacing.md)
            .padding(.vertical, FGSpacing.sm)
            .background(isSelected ? FGColors.accentPrimary : FGColors.backgroundElevated)
            .foregroundColor(isSelected ? .white : FGColors.textSecondary)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : FGColors.borderSubtle, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ExploreTab(viewModel: FlyerCreationViewModel())
}
