import SwiftUI
import SwiftData

struct GalleryTab: View {
    @ObservedObject var viewModel: FlyerCreationViewModel
    @Binding var selectedTab: Int
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SavedFlyer.createdAt, order: .reverse) private var savedFlyers: [SavedFlyer]
    @State private var selectedFlyer: SavedFlyer?

    private let columns = [
        GridItem(.flexible(), spacing: FGSpacing.md),
        GridItem(.flexible(), spacing: FGSpacing.md)
    ]

    var body: some View {
        NavigationStack {
            Group {
                if savedFlyers.isEmpty {
                    emptyState
                } else {
                    flyerGrid
                }
            }
            .background(FGColors.backgroundPrimary)
            .navigationTitle("My Flyers")
            .sheet(item: $selectedFlyer) { flyer in
                FlyerDetailSheet(flyer: flyer) { savedFlyer in
                    // Use as template callback
                    viewModel.loadFromSavedFlyer(savedFlyer)
                    selectedTab = 0  // Switch to Home tab
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: FGSpacing.lg) {
            ZStack {
                Circle()
                    .fill(FGColors.accentPrimary.opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 50))
                    .foregroundColor(FGColors.accentPrimary)
            }

            VStack(spacing: FGSpacing.sm) {
                Text("No Flyers Yet")
                    .font(FGTypography.h2)
                    .foregroundColor(FGColors.textPrimary)

                Text("Your created flyers will appear here.\nTap the Home tab to create your first flyer!")
                    .font(FGTypography.body)
                    .foregroundColor(FGColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, FGSpacing.xl)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(FGColors.backgroundPrimary)
    }

    private var flyerGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: FGSpacing.md) {
                ForEach(savedFlyers) { flyer in
                    FlyerThumbnailView(flyer: flyer)
                        .onTapGesture {
                            selectedFlyer = flyer
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                deleteFlyer(flyer)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
            .padding(FGSpacing.screenHorizontal)
        }
        .background(FGColors.backgroundPrimary)
    }

    private func deleteFlyer(_ flyer: SavedFlyer) {
        modelContext.delete(flyer)
        try? modelContext.save()
    }
}

struct FlyerThumbnailView: View {
    let flyer: SavedFlyer

    var body: some View {
        VStack(alignment: .leading, spacing: FGSpacing.sm) {
            // Image thumbnail
            if let imageData = flyer.imageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 150)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: FGSpacing.cardRadius))
            } else {
                RoundedRectangle(cornerRadius: FGSpacing.cardRadius)
                    .fill(FGColors.surfaceDefault)
                    .frame(height: 150)
                    .overlay {
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundColor(FGColors.textTertiary)
                    }
            }

            // Info
            VStack(alignment: .leading, spacing: FGSpacing.xxs) {
                Text(flyer.headline)
                    .font(FGTypography.labelLarge)
                    .foregroundColor(FGColors.textPrimary)
                    .lineLimit(1)

                Text(flyer.categoryName)
                    .font(FGTypography.caption)
                    .foregroundColor(FGColors.textSecondary)

                Text(flyer.createdAt, style: .date)
                    .font(FGTypography.caption)
                    .foregroundColor(FGColors.textTertiary)
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

struct FlyerDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    let flyer: SavedFlyer
    var onUseAsTemplate: ((SavedFlyer) -> Void)?
    @State private var showingShareSheet = false
    @State private var showingSaveSuccess = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: FGSpacing.lg) {
                    // Full image
                    if let imageData = flyer.imageData,
                       let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: FGSpacing.cardRadius))
                            .shadow(color: FGColors.accentPrimary.opacity(0.2), radius: 12)
                            .padding(.horizontal, FGSpacing.screenHorizontal)
                    }

                    // Details
                    VStack(alignment: .leading, spacing: FGSpacing.sm) {
                        DetailRow(label: "Category", value: flyer.categoryName)
                        Divider()
                            .background(FGColors.borderSubtle)
                        DetailRow(label: "Created", value: flyer.createdAt.formatted(date: .long, time: .shortened))
                        Divider()
                            .background(FGColors.borderSubtle)
                        DetailRow(label: "Model", value: flyer.model)
                    }
                    .padding(FGSpacing.cardPadding)
                    .background(FGColors.backgroundElevated)
                    .clipShape(RoundedRectangle(cornerRadius: FGSpacing.cardRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: FGSpacing.cardRadius)
                            .stroke(FGColors.borderSubtle, lineWidth: 1)
                    )
                    .padding(.horizontal, FGSpacing.screenHorizontal)

                    // Save success message
                    if showingSaveSuccess {
                        HStack(spacing: FGSpacing.sm) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(FGColors.success)
                            Text("Saved to Photos!")
                                .font(FGTypography.label)
                                .foregroundColor(FGColors.success)
                        }
                        .padding(FGSpacing.sm)
                        .background(FGColors.success.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: FGSpacing.chipRadius))
                    }

                    // Use as Template button (full width, prominent)
                    if flyer.project != nil {
                        Button {
                            dismiss()
                            onUseAsTemplate?(flyer)
                        } label: {
                            HStack(spacing: FGSpacing.sm) {
                                Image(systemName: "doc.on.doc")
                                Text("Use as Template")
                            }
                            .font(FGTypography.button)
                            .foregroundColor(FGColors.textOnAccent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, FGSpacing.md)
                            .background(FGColors.accentPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: FGSpacing.buttonRadius))
                        }
                        .padding(.horizontal, FGSpacing.screenHorizontal)
                    }

                    // Secondary actions
                    HStack(spacing: FGSpacing.md) {
                        Button {
                            saveToPhotos()
                        } label: {
                            HStack(spacing: FGSpacing.sm) {
                                Image(systemName: "square.and.arrow.down")
                                Text("Save")
                            }
                            .font(FGTypography.button)
                            .foregroundColor(FGColors.accentPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, FGSpacing.md)
                            .background(FGColors.surfaceDefault)
                            .clipShape(RoundedRectangle(cornerRadius: FGSpacing.buttonRadius))
                            .overlay(
                                RoundedRectangle(cornerRadius: FGSpacing.buttonRadius)
                                    .stroke(FGColors.accentPrimary, lineWidth: 1.5)
                            )
                        }

                        Button {
                            showingShareSheet = true
                        } label: {
                            HStack(spacing: FGSpacing.sm) {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share")
                            }
                            .font(FGTypography.button)
                            .foregroundColor(FGColors.accentPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, FGSpacing.md)
                            .background(FGColors.surfaceDefault)
                            .clipShape(RoundedRectangle(cornerRadius: FGSpacing.buttonRadius))
                            .overlay(
                                RoundedRectangle(cornerRadius: FGSpacing.buttonRadius)
                                    .stroke(FGColors.accentPrimary, lineWidth: 1.5)
                            )
                        }
                    }
                    .padding(.horizontal, FGSpacing.screenHorizontal)
                }
                .padding(.vertical, FGSpacing.lg)
            }
            .background(FGColors.backgroundPrimary)
            .navigationTitle(flyer.headline)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(FGColors.accentPrimary)
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let imageData = flyer.imageData,
                   let uiImage = UIImage(data: imageData) {
                    ShareSheet(items: [uiImage])
                }
            }
        }
    }

    private func saveToPhotos() {
        guard let imageData = flyer.imageData,
              let uiImage = UIImage(data: imageData) else { return }
        UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)
        showingSaveSuccess = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showingSaveSuccess = false
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(FGTypography.body)
                .foregroundColor(FGColors.textSecondary)
            Spacer()
            Text(value)
                .font(FGTypography.labelLarge)
                .foregroundColor(FGColors.textPrimary)
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    GalleryTab(viewModel: FlyerCreationViewModel(), selectedTab: .constant(1))
}
