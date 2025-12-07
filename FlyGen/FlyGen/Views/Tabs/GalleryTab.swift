import SwiftUI
import SwiftData

struct GalleryTab: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SavedFlyer.createdAt, order: .reverse) private var savedFlyers: [SavedFlyer]
    @State private var selectedFlyer: SavedFlyer?

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
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
            .navigationTitle("My Flyers")
            .sheet(item: $selectedFlyer) { flyer in
                FlyerDetailSheet(flyer: flyer)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("No Flyers Yet")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Your created flyers will appear here.\nTap the Home tab to create your first flyer!")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    private var flyerGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
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
            .padding()
        }
    }

    private func deleteFlyer(_ flyer: SavedFlyer) {
        modelContext.delete(flyer)
        try? modelContext.save()
    }
}

struct FlyerThumbnailView: View {
    let flyer: SavedFlyer

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Image thumbnail
            if let imageData = flyer.imageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 150)
                    .clipped()
                    .cornerRadius(12)
            } else {
                Rectangle()
                    .fill(Color.secondary.opacity(0.2))
                    .frame(height: 150)
                    .cornerRadius(12)
                    .overlay {
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                    }
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(flyer.headline)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                Text(flyer.categoryName)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(flyer.createdAt, style: .date)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(8)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct FlyerDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    let flyer: SavedFlyer
    @State private var showingShareSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Full image
                    if let imageData = flyer.imageData,
                       let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(12)
                            .padding(.horizontal)
                    }

                    // Details
                    VStack(alignment: .leading, spacing: 12) {
                        DetailRow(label: "Category", value: flyer.categoryName)
                        DetailRow(label: "Created", value: flyer.createdAt.formatted(date: .long, time: .shortened))
                        DetailRow(label: "Model", value: flyer.model)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)

                    // Actions
                    HStack(spacing: 16) {
                        Button {
                            saveToPhotos()
                        } label: {
                            Label("Save to Photos", systemImage: "square.and.arrow.down")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)

                        Button {
                            showingShareSheet = true
                        } label: {
                            Label("Share", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle(flyer.headline)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
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
    }
}

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
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
    GalleryTab()
}
