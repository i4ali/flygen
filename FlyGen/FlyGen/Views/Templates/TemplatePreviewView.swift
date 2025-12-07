import SwiftUI

struct TemplatePreviewView: View {
    let template: FlyerTemplate
    @ObservedObject var viewModel: FlyerCreationViewModel
    let onDismissParent: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Template preview card
                    templatePreviewCard

                    // Template details
                    templateDetails

                    // Placeholder fields preview
                    placeholderFieldsSection

                    // Use template button
                    Button {
                        viewModel.loadTemplate(template)
                        dismiss()
                        onDismissParent()
                    } label: {
                        HStack {
                            Image(systemName: "doc.badge.plus")
                            Text("Use This Template")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .cornerRadius(12)
                    }
                    .padding(.top, 8)
                }
                .padding()
            }
            .navigationTitle(template.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Template Preview Card

    private var templatePreviewCard: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: template.colors.preset.previewColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Content preview
            VStack(spacing: 12) {
                Image(systemName: template.category.icon)
                    .font(.system(size: 40))

                Text(template.textContent.headline)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                if let subheadline = template.textContent.subheadline {
                    Text(subheadline)
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                }

                if let cta = template.textContent.ctaText {
                    Text(cta)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.3))
                        .cornerRadius(8)
                        .padding(.top, 8)
                }
            }
            .padding(24)
            .foregroundColor(template.colors.backgroundType == .dark ? .white : .primary)
        }
        .frame(height: 280)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
    }

    // MARK: - Template Details

    private var templateDetails: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("About This Template")
                .font(.headline)

            Text(template.previewDescription)
                .font(.body)
                .foregroundColor(.secondary)

            // Style badges
            HStack(spacing: 12) {
                StyleBadge(
                    icon: "paintpalette",
                    title: template.colors.preset.displayName
                )
                StyleBadge(
                    icon: "sparkles",
                    title: template.visuals.style.displayName
                )
                StyleBadge(
                    icon: "face.smiling",
                    title: template.visuals.mood.displayName
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Placeholder Fields Section

    private var placeholderFieldsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Fields to Customize")
                .font(.headline)

            Text("These fields are pre-filled with placeholder text. Replace them with your own content.")
                .font(.caption)
                .foregroundColor(.secondary)

            VStack(spacing: 8) {
                ForEach(placeholderFields, id: \.label) { field in
                    PlaceholderFieldRow(label: field.label, value: field.value)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    // Extract placeholder fields from template
    private var placeholderFields: [(label: String, value: String)] {
        var fields: [(String, String)] = []

        fields.append(("Headline", template.textContent.headline))

        if let sub = template.textContent.subheadline, !sub.isEmpty {
            fields.append(("Subheadline", sub))
        }
        if let body = template.textContent.bodyText, !body.isEmpty {
            fields.append(("Body Text", body))
        }
        if let date = template.textContent.date, !date.isEmpty {
            fields.append(("Date", date))
        }
        if let time = template.textContent.time, !time.isEmpty {
            fields.append(("Time", time))
        }
        if let venue = template.textContent.venueName, !venue.isEmpty {
            fields.append(("Venue", venue))
        }
        if let address = template.textContent.address, !address.isEmpty {
            fields.append(("Address", address))
        }
        if let price = template.textContent.price, !price.isEmpty {
            fields.append(("Price", price))
        }
        if let discount = template.textContent.discountText, !discount.isEmpty {
            fields.append(("Discount", discount))
        }
        if let cta = template.textContent.ctaText, !cta.isEmpty {
            fields.append(("Call to Action", cta))
        }
        if let phone = template.textContent.phone, !phone.isEmpty {
            fields.append(("Phone", phone))
        }
        if let website = template.textContent.website, !website.isEmpty {
            fields.append(("Website", website))
        }
        if let fine = template.textContent.finePrint, !fine.isEmpty {
            fields.append(("Fine Print", fine))
        }

        return fields
    }
}

// MARK: - Style Badge

private struct StyleBadge: View {
    let icon: String
    let title: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(title)
                .font(.caption)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(.systemGray5))
        .cornerRadius(16)
    }
}

// MARK: - Placeholder Field Row

private struct PlaceholderFieldRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)

            Text(value)
                .font(.subheadline)
                .foregroundColor(.primary)
                .lineLimit(1)

            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    TemplatePreviewView(
        template: TemplateLibrary.templates[0],
        viewModel: FlyerCreationViewModel(),
        onDismissParent: {}
    )
}
