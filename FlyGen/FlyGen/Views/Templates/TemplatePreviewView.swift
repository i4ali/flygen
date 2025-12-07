import SwiftUI

struct TemplatePreviewView: View {
    let template: FlyerTemplate
    @ObservedObject var viewModel: FlyerCreationViewModel
    let onDismissParent: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: FGSpacing.xl) {
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
                        HStack(spacing: FGSpacing.sm) {
                            Image(systemName: "doc.badge.plus")
                            Text("Use This Template")
                        }
                        .font(FGTypography.buttonLarge)
                        .foregroundColor(FGColors.textOnAccent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, FGSpacing.md)
                        .background(FGColors.accentPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: FGSpacing.buttonRadius))
                        .shadow(color: FGColors.accentPrimary.opacity(0.4), radius: 12, y: 4)
                    }
                    .padding(.top, FGSpacing.sm)
                }
                .padding(FGSpacing.screenHorizontal)
            }
            .background(FGColors.backgroundPrimary)
            .navigationTitle(template.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(FGColors.accentPrimary)
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
            VStack(spacing: FGSpacing.md) {
                Image(systemName: template.category.icon)
                    .font(.system(size: 40))

                Text(template.textContent.headline)
                    .font(FGTypography.h2)
                    .multilineTextAlignment(.center)

                if let subheadline = template.textContent.subheadline {
                    Text(subheadline)
                        .font(FGTypography.body)
                        .multilineTextAlignment(.center)
                }

                if let cta = template.textContent.ctaText {
                    Text(cta)
                        .font(FGTypography.captionBold)
                        .padding(.horizontal, FGSpacing.md)
                        .padding(.vertical, FGSpacing.sm)
                        .background(Color.white.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: FGSpacing.chipRadius))
                        .padding(.top, FGSpacing.sm)
                }
            }
            .padding(FGSpacing.xl)
            .foregroundColor(template.colors.backgroundType == .dark ? .white : .black)
        }
        .frame(height: 280)
        .clipShape(RoundedRectangle(cornerRadius: FGSpacing.cardRadius))
        .shadow(color: FGColors.accentPrimary.opacity(0.2), radius: 12, y: 4)
    }

    // MARK: - Template Details

    private var templateDetails: some View {
        VStack(alignment: .leading, spacing: FGSpacing.md) {
            Text("About This Template")
                .font(FGTypography.h3)
                .foregroundColor(FGColors.textPrimary)

            Text(template.previewDescription)
                .font(FGTypography.body)
                .foregroundColor(FGColors.textSecondary)

            // Style badges
            HStack(spacing: FGSpacing.sm) {
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
        VStack(alignment: .leading, spacing: FGSpacing.sm) {
            Text("Fields to Customize")
                .font(FGTypography.h4)
                .foregroundColor(FGColors.textPrimary)

            Text("These fields are pre-filled with placeholder text. Replace them with your own content.")
                .font(FGTypography.caption)
                .foregroundColor(FGColors.textSecondary)

            VStack(spacing: FGSpacing.xs) {
                ForEach(placeholderFields, id: \.label) { field in
                    PlaceholderFieldRow(label: field.label, value: field.value)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(FGSpacing.cardPadding)
        .background(FGColors.backgroundElevated)
        .clipShape(RoundedRectangle(cornerRadius: FGSpacing.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: FGSpacing.cardRadius)
                .stroke(FGColors.borderSubtle, lineWidth: 1)
        )
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
        HStack(spacing: FGSpacing.xxs) {
            Image(systemName: icon)
                .font(.caption2)
            Text(title)
                .font(FGTypography.caption)
        }
        .foregroundColor(FGColors.textSecondary)
        .padding(.horizontal, FGSpacing.sm)
        .padding(.vertical, FGSpacing.xs)
        .background(FGColors.surfaceDefault)
        .clipShape(Capsule())
    }
}

// MARK: - Placeholder Field Row

private struct PlaceholderFieldRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(FGTypography.label)
                .foregroundColor(FGColors.textSecondary)
                .frame(width: 100, alignment: .leading)

            Text(value)
                .font(FGTypography.body)
                .foregroundColor(FGColors.textPrimary)
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
