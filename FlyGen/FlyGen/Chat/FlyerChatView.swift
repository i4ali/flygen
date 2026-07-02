import SwiftUI
import SwiftData
import UIKit
import PhotosUI

struct FlyerChatView: View {
    @StateObject private var vm = FlyerChatViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: FGSpacing.md) {
                            ForEach(vm.transcript) { bubble in
                                bubbleView(bubble).id(bubble.id)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding(FGSpacing.screenHorizontal)
                    }
                    .onChange(of: vm.transcript.count) { _, _ in
                        if let last = vm.transcript.last {
                            withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                        }
                    }
                }
                composer
            }
            .background(FGColors.backgroundPrimary.ignoresSafeArea())
            .navigationTitle("Chat (Beta)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }.foregroundColor(FGColors.textSecondary)
                }
            }
            .onAppear { vm.start() }
        }
    }

    /// The most recent "Here's what I got" card — only it stays expanded; older ones collapse.
    private var latestParsedFieldsID: UUID? {
        vm.transcript.last { if case .parsedFields = $0.kind { return true } else { return false } }?.id
    }

    @ViewBuilder
    private func bubbleView(_ bubble: ChatBubble) -> some View {
        switch bubble.kind {
        case .user(let t):        UserBubble(text: t)
        case .userPhotos(let p):  UserPhotosBubble(photos: p)
        case .assistant(let t):   AssistantBubble(text: t)
        case .photoSuggestion(let t, let resolved): PhotoSuggestionBubble(text: t, selection: $vm.photoPickerItems, disabled: vm.isStreaming, resolved: resolved, onDecline: { vm.declinePhotoSuggestion() })
        case .typing(let t):      TypingBubble(text: t)
        case .parsedFields(let b): ParsedFieldsCard(brief: b, expanded: bubble.id == latestParsedFieldsID)
        case .questions(let qs, let stage):  QuestionsCard(questions: qs, onSubmit: { vm.submitAnswers($0, order: $1, stage: stage) })
        case .designBrief(let d): DesignNotesCard(brief: d)
        case .review(let r):      ReviewCard(review: r, onApprove: { vm.approve(fieldOverrides: $0, decisionOverrides: $1, selectedElements: $2) })
        case .concepts(let cs):   ConceptsCard(concepts: cs,
                                      onRefine: { vm.refine(concept: $0, instruction: $1) },
                                      onResize: { vm.resize(concept: $0, aspect: $1) },
                                      onAddToMyFlyers: { addToMyFlyers($0) })
        case .error(let m):       ErrorBubble(text: m)
        }
    }

    /// Persist a chat concept into My Flyers (a SavedFlyer) so it appears in the Gallery tab
    /// and syncs via iCloud, alongside classic flyers.
    private func addToMyFlyers(_ concept: ConceptDTO) {
        guard let imageData = concept.imageData, let project = vm.chatFlyerProject() else { return }
        let generated = GeneratedFlyer(projectId: project.id, imageData: imageData,
                                       prompt: "", negativePrompt: "", model: "")
        modelContext.insert(SavedFlyer(project: project, generatedFlyer: generated))
        try? modelContext.save()
    }

    private var composer: some View {
        VStack(spacing: FGSpacing.xs) {
            if !vm.attachedPhotos.isEmpty { photoStrip }
            HStack(spacing: FGSpacing.sm) {
                TextField("Describe a flyer (starts a new one)…", text: $vm.composerText, axis: .vertical)
                    .textFieldStyle(.plain).font(FGTypography.body).foregroundColor(FGColors.textPrimary)
                    .lineLimit(1...4)
                    .padding(.horizontal, FGSpacing.md).padding(.vertical, FGSpacing.sm)
                    .background(FGColors.surfaceDefault).clipShape(RoundedRectangle(cornerRadius: FGSpacing.inputRadius))
                    .disabled(vm.isStreaming)
                Button { vm.send() } label: {
                    Image(systemName: "arrow.up.circle.fill").font(.system(size: 32))
                        .foregroundColor(vm.canSend ? FGColors.accentPrimary : FGColors.textTertiary)
                }
                .disabled(!vm.canSend)
            }
        }
        .padding(FGSpacing.sm)
        .background(FGColors.backgroundSecondary)
        // Loads whatever the composer strip or the in-chat photo-suggestion picker selects.
        .onChange(of: vm.photoPickerItems) { _, _ in Task { await vm.loadAttachedPhotos() } }
    }

    private var photoStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: FGSpacing.xs) {
                ForEach(Array(vm.attachedPhotos.enumerated()), id: \.offset) { idx, data in
                    if let ui = UIImage(data: data) {
                        Image(uiImage: ui).resizable().scaledToFill()
                            .frame(width: 52, height: 52)
                            .clipShape(RoundedRectangle(cornerRadius: FGSpacing.chipRadius))
                            .overlay(alignment: .topTrailing) {
                                Button { vm.removePhoto(at: idx) } label: {
                                    Image(systemName: "xmark.circle.fill").font(.system(size: 16))
                                        .foregroundColor(.white)
                                        .background(Circle().fill(Color.black.opacity(0.5)))
                                }
                                .padding(2)
                            }
                    }
                }
            }
            .padding(.horizontal, FGSpacing.xxs)
        }
        .frame(height: 56)
    }
}

// MARK: - Small bubbles

private struct UserBubble: View {
    let text: String
    var body: some View {
        HStack { Spacer(minLength: FGSpacing.xl)
            Text(text).font(FGTypography.body).foregroundColor(FGColors.textOnAccent)
                .padding(.horizontal, FGSpacing.md).padding(.vertical, FGSpacing.sm)
                .background(FGColors.accentPrimary).clipShape(RoundedRectangle(cornerRadius: FGSpacing.cardRadius))
        }
    }
}
private struct UserPhotosBubble: View {
    let photos: [Data]
    var body: some View {
        HStack { Spacer(minLength: FGSpacing.xl)
            HStack(spacing: FGSpacing.xs) {
                ForEach(Array(photos.enumerated()), id: \.offset) { _, data in
                    if let ui = UIImage(data: data) {
                        Image(uiImage: ui).resizable().scaledToFill()
                            .frame(width: 96, height: 96)
                            .clipShape(RoundedRectangle(cornerRadius: FGSpacing.cardRadius))
                    }
                }
            }
        }
    }
}
private struct AssistantBubble: View {
    let text: String
    var body: some View {
        Text(text).font(FGTypography.body).foregroundColor(FGColors.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
/// The brain's proactive "add a photo of X" nudge, rendered as a distinct accent-tinted bubble
/// with an inline picker - so it reads as its own message and is one tap to act on. This is the
/// only photo entry point now that the composer's picker button is hidden.
private struct PhotoSuggestionBubble: View {
    let text: String
    @Binding var selection: [PhotosPickerItem]
    var disabled: Bool
    var resolved: Bool                 // once the user has added a photo or declined, hide "No thanks"
    var onDecline: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: FGSpacing.sm) {
            HStack(alignment: .top, spacing: FGSpacing.sm) {
                Image(systemName: "camera.fill").font(.system(size: 16))
                    .foregroundColor(FGColors.accentSecondary).padding(.top, 2)
                Text(text).font(FGTypography.body).foregroundColor(FGColors.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            HStack(spacing: FGSpacing.sm) {
                PhotosPicker(selection: $selection, maxSelectionCount: nil, matching: .images) {
                    Label("Add a photo", systemImage: "plus").font(FGTypography.button)
                        .foregroundColor(FGColors.textOnAccent)
                        .frame(maxWidth: .infinity).padding(.vertical, FGSpacing.sm)
                        .background(FGColors.accentPrimary).clipShape(RoundedRectangle(cornerRadius: FGSpacing.buttonRadius))
                }
                .disabled(disabled)
                if !resolved {
                    Button(action: onDecline) {
                        Text("No thanks").font(FGTypography.button)
                            .foregroundColor(FGColors.textSecondary)
                            .frame(maxWidth: .infinity).padding(.vertical, FGSpacing.sm)
                            .background(FGColors.surfaceDefault).clipShape(RoundedRectangle(cornerRadius: FGSpacing.buttonRadius))
                    }
                    .disabled(disabled)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(FGSpacing.md)
        .background(FGColors.accentSecondary.opacity(0.10)).clipShape(RoundedRectangle(cornerRadius: FGSpacing.cardRadius))
        .overlay(RoundedRectangle(cornerRadius: FGSpacing.cardRadius).stroke(FGColors.accentSecondary.opacity(0.35), lineWidth: 1))
    }
}
private struct TypingBubble: View {
    let text: String
    var body: some View {
        HStack(spacing: FGSpacing.xs) {
            ProgressView().tint(FGColors.accentSecondary).scaleEffect(0.8)
            Text(text).font(FGTypography.bodySmall).foregroundColor(FGColors.textTertiary)
        }
    }
}
private struct ErrorBubble: View {
    let text: String
    var body: some View {
        HStack(alignment: .top, spacing: FGSpacing.xs) {
            Image(systemName: "exclamationmark.triangle.fill").foregroundColor(FGColors.error)
            Text(text).font(FGTypography.bodySmall).foregroundColor(FGColors.textSecondary)
        }
        .padding(FGSpacing.sm).frame(maxWidth: .infinity, alignment: .leading)
        .background(FGColors.error.opacity(0.1)).clipShape(RoundedRectangle(cornerRadius: FGSpacing.chipRadius))
    }
}

// MARK: - Shared pieces

private struct AssistantCard<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: FGSpacing.sm) { content }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(FGSpacing.md)
            .background(FGColors.surfaceDefault).clipShape(RoundedRectangle(cornerRadius: FGSpacing.cardRadius))
            .overlay(RoundedRectangle(cornerRadius: FGSpacing.cardRadius).stroke(FGColors.borderSubtle, lineWidth: 1))
    }
}
private struct SourceBadge: View {
    let source: String
    var body: some View {
        let stated = source == "stated"
        Text(source.uppercased()).font(FGTypography.captionSmall)
            .foregroundColor(stated ? FGColors.success : FGColors.warning)
            .padding(.horizontal, FGSpacing.xs).padding(.vertical, 2)
            .background((stated ? FGColors.success : FGColors.warning).opacity(0.15)).clipShape(Capsule())
    }
}

// MARK: - Cards

private struct ParsedFieldsCard: View {
    let brief: ExtractedBriefDTO
    var expanded: Bool = true
    @State private var userToggled: Bool? = nil   // follows `expanded` until the user overrides
    var body: some View {
        AssistantCard {
            DisclosureGroup(isExpanded: Binding(get: { userToggled ?? expanded },
                                                set: { userToggled = $0 })) {
                ForEach(brief.displayFields, id: \.key) { f in
                    HStack(alignment: .top, spacing: FGSpacing.xs) {
                        Text(f.key.replacingOccurrences(of: "_", with: " "))
                            .font(FGTypography.caption).foregroundColor(FGColors.textTertiary)
                            .frame(width: 92, alignment: .leading)
                        Text(prettyValue(f.key, f.value)).font(FGTypography.bodySmall).foregroundColor(FGColors.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        SourceBadge(source: f.source)
                    }
                }
                .padding(.top, FGSpacing.xs)
            } label: {
                Text("Here's what I got").font(FGTypography.h4).foregroundColor(FGColors.textPrimary)
            }.tint(FGColors.accentSecondary)
        }
    }
    /// Category arrives as a raw enum value ("church_religious"); show its canonical display name
    /// ("Church & Faith") - the same one the review card uses - so the two cards never disagree.
    private func prettyValue(_ key: String, _ value: String) -> String {
        guard key == "category" else { return value }
        if let category = FlyerCategory(rawValue: value) { return category.displayName }
        return value.split(separator: "_").map { $0.prefix(1).uppercased() + $0.dropFirst() }.joined(separator: " ")
    }
}

private struct QuestionsCard: View {
    let questions: [QuestionDTO]
    let onSubmit: ([String: String], [String]) -> Void
    @State private var answers: [String: String] = [:]
    @State private var submitted = false
    private var heading: String {
        switch questions.count {
        case 1:  return "One quick thing"
        case 2:  return "A couple of quick questions"
        default: return "A few quick questions"
        }
    }
    var body: some View {
        AssistantCard {
            Text(heading).font(FGTypography.h4).foregroundColor(FGColors.textPrimary)
            ForEach(questions) { q in
                VStack(alignment: .leading, spacing: FGSpacing.xxs) {
                    Text(q.text).font(FGTypography.bodySmall).foregroundColor(FGColors.textSecondary)
                    if let opts = q.options, !opts.isEmpty {
                        choicePicker(q.field, opts)          // labeled picker (e.g. size)
                    } else {
                        TextField("Your answer", text: Binding(get: { answers[q.field] ?? "" }, set: { answers[q.field] = $0 }))
                            .textFieldStyle(.plain).font(FGTypography.body).foregroundColor(FGColors.textPrimary)
                            .padding(.horizontal, FGSpacing.sm).padding(.vertical, FGSpacing.xs)
                            .background(FGColors.backgroundTertiary).clipShape(RoundedRectangle(cornerRadius: FGSpacing.inputRadius))
                            .disabled(submitted)
                    }
                }
            }
            Button { submitted = true; onSubmit(answers, questions.map { $0.field }) } label: {
                Text("Send answers").font(FGTypography.button).foregroundColor(FGColors.textOnAccent)
                    .frame(maxWidth: .infinity).padding(.vertical, FGSpacing.sm)
                    .background(FGColors.accentPrimary).clipShape(RoundedRectangle(cornerRadius: FGSpacing.buttonRadius))
            }.disabled(submitted)
        }
        .onAppear {
            // Pre-select each picker's default (first option) so the size is sent even untouched.
            for q in questions where !(q.options ?? []).isEmpty {
                if answers[q.field] == nil { answers[q.field] = q.options?.first?.value }
            }
        }
    }

    @ViewBuilder
    private func choicePicker(_ field: String, _ opts: [FormatOptionDTO]) -> some View {
        let current = answers[field] ?? opts.first?.value ?? ""
        Menu {
            ForEach(opts, id: \.value) { opt in Button(opt.label) { answers[field] = opt.value } }
        } label: {
            HStack {
                Text(opts.first(where: { $0.value == current })?.label ?? current)
                    .font(FGTypography.body).foregroundColor(FGColors.textPrimary)
                Spacer()
                Image(systemName: "chevron.up.chevron.down").font(.system(size: 11)).foregroundColor(FGColors.textTertiary)
            }
            .padding(.horizontal, FGSpacing.sm).padding(.vertical, FGSpacing.xs)
            .background(FGColors.backgroundTertiary).clipShape(RoundedRectangle(cornerRadius: FGSpacing.inputRadius))
        }
        .disabled(submitted)
    }
}

private struct DesignNotesCard: View {
    let brief: DesignBriefDTO
    var body: some View {
        AssistantCard {
            if !brief.notes.isEmpty {
                Text(brief.notes).font(FGTypography.bodySmall).foregroundColor(FGColors.textSecondary)
            }
            DisclosureGroup {
                if !brief.checklist.isEmpty {
                    Text("Checklist").font(FGTypography.captionBold).foregroundColor(FGColors.textTertiary).padding(.top, FGSpacing.xs)
                    ForEach(brief.checklist, id: \.self) { bullet($0, "checkmark.circle") }
                }
                if !brief.recommendations.isEmpty {
                    Text("Recommendations").font(FGTypography.captionBold).foregroundColor(FGColors.textTertiary).padding(.top, FGSpacing.xs)
                    ForEach(brief.recommendations, id: \.self) { bullet($0, "lightbulb") }
                }
            } label: {
                Text("Design notes").font(FGTypography.h4).foregroundColor(FGColors.textPrimary)
            }.tint(FGColors.accentSecondary)
        }
    }
    @ViewBuilder private func bullet(_ text: String, _ icon: String) -> some View {
        HStack(alignment: .top, spacing: FGSpacing.xs) {
            Image(systemName: icon).font(.system(size: 11)).foregroundColor(FGColors.accentSecondary).padding(.top, 2)
            Text(text).font(FGTypography.bodySmall).foregroundColor(FGColors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct ReviewCard: View {
    let review: ReviewProposalDTO
    let onApprove: (_ fieldOverrides: [String: String], _ decisionOverrides: [String: String], _ selectedElements: [String]?) -> Void
    @State private var fieldValues: [String: String] = [:]
    @State private var decisionValues: [String: String] = [:]
    @State private var elementSelected: [String: Bool] = [:]
    @State private var approved = false
    var body: some View {
        AssistantCard {
            Text("Review before I generate").font(FGTypography.h4).foregroundColor(FGColors.textPrimary)
            ForEach(review.fields) { f in
                VStack(alignment: .leading, spacing: FGSpacing.xxs) {
                    HStack { Text(f.key.replacingOccurrences(of: "_", with: " "))
                        .font(FGTypography.caption).foregroundColor(FGColors.textTertiary)
                        Spacer(); SourceBadge(source: f.source) }
                    TextField("", text: Binding(get: { fieldValues[f.key] ?? f.value }, set: { fieldValues[f.key] = $0 }))
                        .textFieldStyle(.plain).font(FGTypography.bodySmall).foregroundColor(FGColors.textPrimary)
                        .padding(.horizontal, FGSpacing.sm).padding(.vertical, FGSpacing.xs)
                        .background(FGColors.backgroundTertiary).clipShape(RoundedRectangle(cornerRadius: FGSpacing.inputRadius))
                        .overlay(RoundedRectangle(cornerRadius: FGSpacing.inputRadius)   // amber outline when flagged
                            .stroke(FGColors.warning, lineWidth: f.warning == nil ? 0 : 1))
                        .disabled(approved)
                    if let w = f.warning { warningLine(w) }   // the value needs attention (e.g. a malformed URL)
                }
            }
            Divider().background(FGColors.borderSubtle)
            ForEach(review.decisions) { d in
                VStack(alignment: .leading, spacing: FGSpacing.xxs) {
                    Text(d.label).font(FGTypography.caption).foregroundColor(FGColors.textTertiary)
                    Menu {
                        ForEach(d.options, id: \.self) { opt in
                            Button(d.option_labels?[opt] ?? opt) { decisionValues[d.key] = opt }
                        }
                    } label: {
                        HStack {
                            let cur = decisionValues[d.key] ?? d.value
                            Text(d.option_labels?[cur] ?? cur).font(FGTypography.bodySmall).foregroundColor(FGColors.textPrimary)
                            Spacer()
                            Image(systemName: "chevron.up.chevron.down").font(.system(size: 11)).foregroundColor(FGColors.textTertiary)
                        }
                        .padding(.horizontal, FGSpacing.sm).padding(.vertical, FGSpacing.xs)
                        .background(FGColors.backgroundTertiary).clipShape(RoundedRectangle(cornerRadius: FGSpacing.inputRadius))
                    }.disabled(approved)
                    if d.supported == false {       // engine flagged this value as off-vocabulary
                        warningLine("Not a standard option - pick a suggested value above.")
                    }
                    if !d.reason.isEmpty {
                        Text(d.reason).font(FGTypography.captionSmall).foregroundColor(FGColors.textTertiary)
                    }
                }
            }
            creativeIdeas
            designNotes
            Button {
                approved = true
                let fo = fieldValues.filter { key, val in review.fields.first(where: { $0.key == key })?.value != val }
                var dov: [String: String] = [:]
                for d in review.decisions { dov[d.key] = decisionValues[d.key] ?? d.value }
                onApprove(fo, dov, selectedElements())
            } label: {
                Text("Approve & generate 3 concepts").font(FGTypography.button).foregroundColor(FGColors.textOnAccent)
                    .frame(maxWidth: .infinity).padding(.vertical, FGSpacing.sm)
                    .background(FGColors.accentPrimary).clipShape(RoundedRectangle(cornerRadius: FGSpacing.buttonRadius))
            }.disabled(approved)
        }
    }

    // Proactive creative ideas: safe ones default on, sensitive ones default off; the user toggles.
    @ViewBuilder private var creativeIdeas: some View {
        if let elements = review.creative_elements, !elements.isEmpty {
            Divider().background(FGColors.borderSubtle)
            Text("Creative ideas").font(FGTypography.caption).foregroundColor(FGColors.textTertiary)
            ForEach(elements) { e in
                HStack(alignment: .top, spacing: FGSpacing.sm) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: FGSpacing.xxs) {
                            Text(e.what).font(FGTypography.bodySmall).foregroundColor(FGColors.textPrimary)
                            if e.sensitivity == "sensitive" {
                                Text("SENSITIVE").font(FGTypography.captionSmall).foregroundColor(FGColors.warning)
                                    .padding(.horizontal, FGSpacing.xxs).padding(.vertical, 1)
                                    .background(FGColors.warning.opacity(0.15)).clipShape(Capsule())
                            }
                        }
                        if let why = e.why, !why.isEmpty {
                            Text(why).font(FGTypography.captionSmall).foregroundColor(FGColors.textTertiary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    Spacer()
                    Toggle("", isOn: Binding(get: { isElementOn(e) }, set: { elementSelected[e.what] = $0 }))
                        .labelsHidden().tint(FGColors.accentPrimary).disabled(approved)
                }
            }
        }
    }

    // The design brief now rides inside review.plan; surface it (older builds got a separate event).
    @ViewBuilder private var designNotes: some View {
        if let plan = review.plan, !(plan.notes.isEmpty && plan.checklist.isEmpty && plan.recommendations.isEmpty) {
            Divider().background(FGColors.borderSubtle)
            if !plan.notes.isEmpty {
                Text(plan.notes).font(FGTypography.bodySmall).foregroundColor(FGColors.textSecondary)
            }
            if !plan.checklist.isEmpty || !plan.recommendations.isEmpty {
                DisclosureGroup {
                    ForEach(plan.checklist, id: \.self) { planBullet($0, "checkmark.circle") }
                    ForEach(plan.recommendations, id: \.self) { planBullet($0, "lightbulb") }
                } label: {
                    Text("Design notes").font(FGTypography.captionBold).foregroundColor(FGColors.textTertiary)
                }.tint(FGColors.accentSecondary)
            }
        }
    }

    private func isElementOn(_ e: CreativeProposalDTO) -> Bool {
        elementSelected[e.what] ?? (e.selected ?? (e.sensitivity == "safe"))
    }
    /// nil when no creative ideas were offered (engine keeps its safe defaults); otherwise the chosen set.
    private func selectedElements() -> [String]? {
        guard let elements = review.creative_elements, !elements.isEmpty else { return nil }
        return elements.filter { isElementOn($0) }.map { $0.what }
    }
    @ViewBuilder private func warningLine(_ text: String) -> some View {
        HStack(alignment: .top, spacing: FGSpacing.xxs) {
            Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 10)).foregroundColor(FGColors.warning)
            Text(text).font(FGTypography.captionSmall).foregroundColor(FGColors.warning)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    @ViewBuilder private func planBullet(_ text: String, _ icon: String) -> some View {
        HStack(alignment: .top, spacing: FGSpacing.xs) {
            Image(systemName: icon).font(.system(size: 11)).foregroundColor(FGColors.accentSecondary).padding(.top, 2)
            Text(text).font(FGTypography.captionSmall).foregroundColor(FGColors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct ConceptsCard: View {
    let concepts: [ConceptDTO]
    let onRefine: (ConceptDTO, String) -> Void
    let onResize: (ConceptDTO, AspectRatio) -> Void
    let onAddToMyFlyers: (ConceptDTO) -> Void
    @State private var refineText: [String: String] = [:]
    @State private var savedVersionIDs: Set<String> = []
    var body: some View {
        AssistantCard {
            Text(concepts.count > 1 ? "Three concepts" : "Updated concept").font(FGTypography.h4).foregroundColor(FGColors.textPrimary)
            ForEach(concepts) { c in
                VStack(alignment: .leading, spacing: FGSpacing.xs) {
                    if let data = c.imageData, let ui = UIImage(data: data) {
                        Image(uiImage: ui).resizable().scaledToFit()
                            .frame(maxWidth: .infinity).clipShape(RoundedRectangle(cornerRadius: FGSpacing.inputRadius))
                    } else if let err = c.error {
                        Text(err).font(FGTypography.captionSmall).foregroundColor(FGColors.error)
                    }
                    HStack(spacing: FGSpacing.xs) {
                        TextField("Refine (e.g. warmer, bigger headline)", text: Binding(
                            get: { refineText[c.version_id] ?? "" }, set: { refineText[c.version_id] = $0 }))
                            .textFieldStyle(.plain).font(FGTypography.bodySmall).foregroundColor(FGColors.textPrimary)
                            .padding(.horizontal, FGSpacing.sm).padding(.vertical, FGSpacing.xs)
                            .background(FGColors.backgroundTertiary).clipShape(RoundedRectangle(cornerRadius: FGSpacing.inputRadius))
                        Button {
                            let t = (refineText[c.version_id] ?? "").trimmingCharacters(in: .whitespaces)
                            if !t.isEmpty { onRefine(c, t) }
                        } label: { Image(systemName: "wand.and.stars").foregroundColor(FGColors.accentPrimary) }
                    }
                    HStack(spacing: FGSpacing.md) {
                        Button { save(c) } label: { Label("Photos", systemImage: "square.and.arrow.down").font(FGTypography.buttonSmall) }
                            .foregroundColor(FGColors.accentSecondary)
                        let added = savedVersionIDs.contains(c.version_id)
                        Button {
                            onAddToMyFlyers(c)
                            savedVersionIDs.insert(c.version_id)
                        } label: {
                            Label(added ? "Added" : "My Flyers",
                                  systemImage: added ? "checkmark.circle.fill" : "square.grid.2x2")
                                .font(FGTypography.buttonSmall)
                        }
                        .foregroundColor(added ? FGColors.success : FGColors.accentSecondary)
                        .disabled(added)
                        Menu {
                            ForEach(AspectRatio.allCases) { ar in Button(ar.displayName) { onResize(c, ar) } }
                        } label: { Label("Resize", systemImage: "aspectratio").font(FGTypography.buttonSmall).foregroundColor(FGColors.accentSecondary) }
                    }
                }
                .padding(.bottom, FGSpacing.xs)
            }
        }
    }
    private func save(_ c: ConceptDTO) {
        guard let data = c.imageData else { return }
        Task { try? await PhotoLibraryService.saveImageData(data) }
    }
}
