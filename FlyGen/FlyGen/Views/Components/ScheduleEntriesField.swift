import SwiftUI

/// A component for entering multiple schedule entries (date + activities)
/// Used for multi-date events like workshops, camps, and festivals
struct ScheduleEntriesField: View {
    @Binding var entries: [String]?
    @FocusState private var focusedIndex: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: FGSpacing.md) {
            // Label
            HStack(spacing: FGSpacing.xxs) {
                Text("Schedule")
                    .font(FGTypography.labelLarge)
                    .foregroundColor(FGColors.textPrimary)

                Spacer()

                if let count = entries?.count, count > 0 {
                    Text("\(count) date\(count == 1 ? "" : "s")")
                        .font(FGTypography.captionSmall)
                        .foregroundColor(FGColors.textTertiary)
                }
            }

            // Entries list
            VStack(spacing: FGSpacing.sm) {
                ForEach(Array((entries ?? []).enumerated()), id: \.offset) { index, _ in
                    ScheduleEntryRow(
                        entry: Binding(
                            get: { entries?[index] ?? "" },
                            set: { newValue in
                                if entries == nil { entries = [] }
                                if index < (entries?.count ?? 0) {
                                    entries?[index] = newValue
                                }
                            }
                        ),
                        index: index,
                        onDelete: {
                            withAnimation(FGAnimations.quickEaseOut) {
                                entries?.remove(at: index)
                                if entries?.isEmpty == true {
                                    entries = nil
                                }
                            }
                        },
                        isFocused: $focusedIndex
                    )
                }
            }

            // Add button
            Button {
                withAnimation(FGAnimations.quickEaseOut) {
                    if entries == nil { entries = [] }
                    entries?.append("")
                    // Focus the new entry after a brief delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        focusedIndex = (entries?.count ?? 1) - 1
                    }
                }
            } label: {
                HStack(spacing: FGSpacing.xs) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16))
                    Text("Add Date")
                        .font(FGTypography.label)
                }
                .foregroundColor(FGColors.accentPrimary)
                .padding(.vertical, FGSpacing.sm)
                .frame(maxWidth: .infinity)
                .background(FGColors.accentPrimary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: FGSpacing.inputRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: FGSpacing.inputRadius)
                        .stroke(FGColors.accentPrimary.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
    }
}

/// Individual schedule entry row with date and activities fields
private struct ScheduleEntryRow: View {
    @Binding var entry: String
    let index: Int
    let onDelete: () -> Void
    var isFocused: FocusState<Int?>.Binding

    @State private var date: String = ""
    @State private var activities: String = ""

    var body: some View {
        VStack(spacing: FGSpacing.xs) {
            HStack(alignment: .top, spacing: FGSpacing.sm) {
                VStack(spacing: FGSpacing.xs) {
                    // Date field
                    TextField("Date (e.g., Dec 19th)", text: $date)
                        .font(FGTypography.label)
                        .foregroundColor(FGColors.textPrimary)
                        .textFieldStyle(.plain)
                        .padding(FGSpacing.sm)
                        .background(FGColors.surfaceDefault)
                        .clipShape(RoundedRectangle(cornerRadius: FGSpacing.inputRadius))
                        .overlay(
                            RoundedRectangle(cornerRadius: FGSpacing.inputRadius)
                                .stroke(FGColors.borderSubtle, lineWidth: 1)
                        )
                        .focused(isFocused, equals: index)
                        .onChange(of: date) { _, _ in
                            updateEntry()
                        }

                    // Activities field
                    TextField("Activities (e.g., Workshop A, Class B)", text: $activities)
                        .font(FGTypography.body)
                        .foregroundColor(FGColors.textPrimary)
                        .textFieldStyle(.plain)
                        .padding(FGSpacing.sm)
                        .background(FGColors.surfaceDefault)
                        .clipShape(RoundedRectangle(cornerRadius: FGSpacing.inputRadius))
                        .overlay(
                            RoundedRectangle(cornerRadius: FGSpacing.inputRadius)
                                .stroke(FGColors.borderSubtle, lineWidth: 1)
                        )
                        .onChange(of: activities) { _, _ in
                            updateEntry()
                        }
                }

                // Delete button
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(FGColors.textTertiary)
                }
                .buttonStyle(.plain)
                .padding(.top, FGSpacing.sm)
            }
        }
        .padding(FGSpacing.sm)
        .background(FGColors.backgroundElevated)
        .clipShape(RoundedRectangle(cornerRadius: FGSpacing.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: FGSpacing.cardRadius)
                .stroke(FGColors.borderSubtle, lineWidth: 1)
        )
        .onAppear {
            parseEntry()
        }
        .onChange(of: entry) { _, newValue in
            // Only parse if it's different from what we'd generate
            let generated = generateEntry()
            if newValue != generated {
                parseEntry()
            }
        }
    }

    private func parseEntry() {
        // Parse "Date: Activities" format
        if entry.contains(": ") {
            let parts = entry.split(separator: ": ", maxSplits: 1)
            date = String(parts.first ?? "")
            activities = parts.count > 1 ? String(parts[1]) : ""
        } else if !entry.isEmpty {
            date = entry
            activities = ""
        }
    }

    private func generateEntry() -> String {
        if date.isEmpty && activities.isEmpty {
            return ""
        } else if activities.isEmpty {
            return date
        } else {
            return "\(date): \(activities)"
        }
    }

    private func updateEntry() {
        entry = generateEntry()
    }
}

#Preview("Schedule Entries - Dark Theme") {
    struct PreviewWrapper: View {
        @State var entries: [String]? = [
            "Dec 19th: Roblox Obby Masters, Minecraft Modder",
            "Dec 22-23: Animation Workshop, Escape Room"
        ]

        var body: some View {
            ScrollView {
                VStack(spacing: FGSpacing.lg) {
                    ScheduleEntriesField(entries: $entries)

                    Divider().background(FGColors.borderSubtle)

                    Text("Current entries:")
                        .font(FGTypography.label)
                        .foregroundColor(FGColors.textSecondary)

                    ForEach(entries ?? [], id: \.self) { entry in
                        Text(entry)
                            .font(FGTypography.caption)
                            .foregroundColor(FGColors.textTertiary)
                    }
                }
                .padding(FGSpacing.screenHorizontal)
            }
            .background(FGColors.backgroundPrimary)
        }
    }

    return PreviewWrapper()
}
