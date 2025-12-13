import SwiftUI

/// Sample flyer data for the Explore gallery
struct SampleFlyer: Identifiable {
    let id = UUID()
    let imageName: String
    let title: String
    let category: String
}

struct ExploreTab: View {
    @State private var selectedSample: SampleFlyer?

    /// Sample flyers bundled with the app
    /// These images should be added to Assets.xcassets/SampleFlyers/
    private let sampleFlyers: [SampleFlyer] = [
        SampleFlyer(imageName: "sample_grand_opening", title: "Grand Opening Restaurant", category: "Grand Opening"),
        SampleFlyer(imageName: "sample_tech_conference", title: "Tech Conference", category: "Event"),
        SampleFlyer(imageName: "sample_educational_newsletter", title: "Educational Newsletter", category: "Announcement"),
        SampleFlyer(imageName: "sample_mega_sale", title: "Mega Sale", category: "Sale / Promotion"),
        SampleFlyer(imageName: "sample_brake_service", title: "Brake Service Special", category: "Sale / Promotion"),
        SampleFlyer(imageName: "sample_no_registration", title: "No Registration Fees", category: "Promotion"),
    ]

    private let columns = [
        GridItem(.flexible(), spacing: FGSpacing.md),
        GridItem(.flexible(), spacing: FGSpacing.md)
    ]

    var body: some View {
        NavigationStack {
            Group {
                if sampleFlyers.isEmpty {
                    emptyState
                } else {
                    sampleGrid
                }
            }
            .background(FGColors.backgroundPrimary)
            .navigationTitle("Explore")
            .sheet(item: $selectedSample) { sample in
                SampleDetailSheet(sample: sample)
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

                    Text("Browse sample flyers created with FlyGen")
                        .font(FGTypography.body)
                        .foregroundColor(FGColors.textSecondary)
                }
                .padding(.horizontal, FGSpacing.screenHorizontal)

                // Grid
                LazyVGrid(columns: columns, spacing: FGSpacing.md) {
                    ForEach(sampleFlyers) { sample in
                        SampleThumbnailView(sample: sample)
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
}

// MARK: - Sample Thumbnail View

struct SampleThumbnailView: View {
    let sample: SampleFlyer

    var body: some View {
        VStack(alignment: .leading, spacing: FGSpacing.sm) {
            // Image thumbnail
            if let uiImage = UIImage(named: sample.imageName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 150)
                    .clipped()
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
                    .frame(height: 150)
                    .overlay {
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundColor(FGColors.textTertiary)
                    }
            }

            // Info
            VStack(alignment: .leading, spacing: FGSpacing.xxs) {
                Text(sample.title)
                    .font(FGTypography.labelLarge)
                    .foregroundColor(FGColors.textPrimary)
                    .lineLimit(1)

                Text(sample.category)
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

// MARK: - Sample Detail Sheet (View Only)

struct SampleDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    let sample: SampleFlyer

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
                            Text(sample.category)
                                .font(FGTypography.labelLarge)
                                .foregroundColor(FGColors.textPrimary)
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

                    // Info text
                    Text("This sample was created using FlyGen's AI-powered flyer generator.")
                        .font(FGTypography.caption)
                        .foregroundColor(FGColors.textTertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, FGSpacing.xl)
                }
                .padding(.vertical, FGSpacing.lg)
            }
            .background(FGColors.backgroundPrimary)
            .navigationTitle(sample.title)
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

#Preview {
    ExploreTab()
}
