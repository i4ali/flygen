import SwiftUI
import UIKit
import PhotosUI

struct FlyerChatView: View {
    @StateObject private var vm = FlyerChatViewModel()
    @Environment(\.dismiss) private var dismiss

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
        case .typing(let t):      TypingBubble(text: t)
        case .parsedFields(let b): ParsedFieldsCard(brief: b, expanded: bubble.id == latestParsedFieldsID)
        case .questions(let qs, let stage):  QuestionsCard(questions: qs, onSubmit: { vm.submitAnswers($0, order: $1, stage: stage) })
        case .designBrief(let d): DesignNotesCard(brief: d)
        case .review(let r):      ReviewCard(review: r, onApprove: { vm.approve(fieldOverrides: $0, decisionOverrides: $1) })
        case .concepts(let cs):   ConceptsCard(concepts: cs,
                                      onRefine: { vm.refine(concept: $0, instruction: $1) },
                                      onResize: { vm.resize(concept: $0, aspect: $1) })
        case .error(let m):       ErrorBubble(text: m)
        }
    }

    private var composer: some View {
        VStack(spacing: FGSpacing.xs) {
            if !vm.attachedPhotos.isEmpty { photoStrip }
            HStack(spacing: FGSpacing.sm) {
                PhotosPicker(selection: $vm.photoPickerItems, maxSelectionCount: nil, matching: .images) {
                    Image(systemName: "photo.on.rectangle.angled").font(.system(size: 24))
                        .foregroundColor(vm.isStreaming ? FGColors.textTertiary : FGColors.accentSecondary)
                }
                .disabled(vm.isStreaming)
                .onChange(of: vm.photoPickerItems) { _, _ in Task { await vm.loadAttachedPhotos() } }

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
    /// Category arrives as a raw enum value ("job_posting"); show it titled ("Job Posting").
    private func prettyValue(_ key: String, _ value: String) -> String {
        guard key == "category" else { return value }
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
    let onApprove: (_ fieldOverrides: [String: String], _ decisionOverrides: [String: String]) -> Void
    @State private var fieldValues: [String: String] = [:]
    @State private var decisionValues: [String: String] = [:]
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
                    if let w = f.warning {        // the value needs attention (e.g. a malformed URL)
                        HStack(alignment: .top, spacing: FGSpacing.xxs) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 10)).foregroundColor(FGColors.warning)
                            Text(w).font(FGTypography.captionSmall).foregroundColor(FGColors.warning)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
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
                    Text(d.reason).font(FGTypography.captionSmall).foregroundColor(FGColors.textTertiary)
                }
            }
            Button {
                approved = true
                let fo = fieldValues.filter { key, val in review.fields.first(where: { $0.key == key })?.value != val }
                var dov: [String: String] = [:]
                for d in review.decisions { dov[d.key] = decisionValues[d.key] ?? d.value }
                onApprove(fo, dov)
            } label: {
                Text("Approve & generate 3 concepts").font(FGTypography.button).foregroundColor(FGColors.textOnAccent)
                    .frame(maxWidth: .infinity).padding(.vertical, FGSpacing.sm)
                    .background(FGColors.accentPrimary).clipShape(RoundedRectangle(cornerRadius: FGSpacing.buttonRadius))
            }.disabled(approved)
        }
    }
}

private struct ConceptsCard: View {
    let concepts: [ConceptDTO]
    let onRefine: (ConceptDTO, String) -> Void
    let onResize: (ConceptDTO, AspectRatio) -> Void
    @State private var refineText: [String: String] = [:]
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
                        Button { save(c) } label: { Label("Save", systemImage: "square.and.arrow.down").font(FGTypography.buttonSmall) }
                            .foregroundColor(FGColors.accentSecondary)
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
