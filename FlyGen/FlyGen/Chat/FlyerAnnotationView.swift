import SwiftUI
import UIKit

// MARK: - Annotation model
//
// A user marks up a flyer by drawing numbered circles and pinning a note to each. The circles +
// numbers get burned into the image we SEND the model; the notes travel as a numbered message
// ("1. ...  2. ..."). See docs/plans/2026-07-04-annotate-to-edit-design.md. Coordinates are stored
// normalized (0...1 of the image) so they survive fit-to-screen scaling and pinch-zoom.

struct Annotation: Identifiable, Equatable {
    let id: UUID
    var rect: CGRect        // normalized 0...1 in image space
    var note: String
    init(id: UUID = UUID(), rect: CGRect, note: String = "") {
        self.id = id; self.rect = rect; self.note = note
    }
}

/// A marked-up edit's full state, kept by the view model so a failed generation can reopen the
/// editor with every circle and note intact (owner's "keep them to retry" choice).
struct AnnotationDraft: Equatable {
    var sourceImageData: Data           // the CLEAN image that was annotated (to reopen on)
    var annotations: [Annotation]
    var generalNote: String
}

/// Drives the annotation editor's `fullScreenCover(item:)`. `seed` is non-nil only when reopening
/// after a failed edit.
struct AnnotationEditorRequest: Identifiable {
    let id = UUID()
    let imageData: Data
    var seed: AnnotationDraft? = nil
}

/// Shared, observable annotation state for one editing session.
final class AnnotationStore: ObservableObject {
    @Published var annotations: [Annotation] = []
    @Published var generalNote: String = ""
}

// MARK: - Drawing (shared by the on-screen overlay and the flattened output)

private let markColor = UIColor(red: 1.0, green: 0.0, blue: 0.588, alpha: 1.0)   // ~#FF0096, high-contrast

/// Draws numbered circles onto `ctx` at the given size. `showNotes` adds a small text tag beside
/// each circle (for the editor); the flattened image we send the model omits them so only circles +
/// numbers reach the model, exactly what the Phase 0 spike validated.
private func drawAnnotations(in ctx: CGContext, size: CGSize, annotations: [Annotation], showNotes: Bool) {
    guard size.width > 0, size.height > 0 else { return }
    let stroke = max(5, size.width * 0.011)
    let badgeR = max(12, size.width * 0.030)
    for (i, a) in annotations.enumerated() {
        let r = CGRect(x: a.rect.minX * size.width, y: a.rect.minY * size.height,
                       width: a.rect.width * size.width, height: a.rect.height * size.height)
        ctx.setStrokeColor(markColor.cgColor)
        ctx.setLineWidth(stroke)
        ctx.strokeEllipse(in: r)

        // Number badge on the circle's top-left edge, so it never covers the circled content.
        let c = CGPoint(x: r.minX, y: r.minY)
        let badge = CGRect(x: c.x - badgeR, y: c.y - badgeR, width: badgeR * 2, height: badgeR * 2)
        ctx.setFillColor(markColor.cgColor)
        ctx.fillEllipse(in: badge)
        let num = "\(i + 1)" as NSString
        let numFont = UIFont.systemFont(ofSize: badgeR * 1.15, weight: .heavy)
        let numAttrs: [NSAttributedString.Key: Any] = [.font: numFont, .foregroundColor: UIColor.white]
        let ns = num.size(withAttributes: numAttrs)
        num.draw(at: CGPoint(x: c.x - ns.width / 2, y: c.y - ns.height / 2), withAttributes: numAttrs)

        if showNotes {
            let note = a.note.trimmingCharacters(in: .whitespacesAndNewlines)
            if !note.isEmpty { drawNoteTag(ctx, near: r, text: note, size: size, badgeR: badgeR) }
        }
    }
}

private func drawNoteTag(_ ctx: CGContext, near r: CGRect, text: String, size: CGSize, badgeR: CGFloat) {
    let maxChars = 22
    let shown = (text.count > maxChars ? String(text.prefix(maxChars)) + "…" : text) as NSString
    let fontSize = max(10, size.width * 0.026)
    let attrs: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: fontSize, weight: .semibold),
        .foregroundColor: UIColor.white,
    ]
    let ts = shown.size(withAttributes: attrs)
    let padH = fontSize * 0.5, padV = fontSize * 0.35
    var tag = CGRect(x: r.minX, y: r.maxY + badgeR * 0.3, width: ts.width + padH * 2, height: ts.height + padV * 2)
    if tag.maxX > size.width { tag.origin.x = max(0, size.width - tag.width) }
    if tag.maxY > size.height { tag.origin.y = r.minY - tag.height - badgeR * 0.3 }   // flip above if it would clip
    let path = UIBezierPath(roundedRect: tag, cornerRadius: tag.height * 0.28)
    ctx.setFillColor(UIColor(red: 0.82, green: 0.0, blue: 0.48, alpha: 0.92).cgColor)
    ctx.addPath(path.cgPath)
    ctx.fillPath()
    shown.draw(at: CGPoint(x: tag.minX + padH, y: tag.minY + padV), withAttributes: attrs)
}

/// Flatten: the CLEAN flyer with numbered circles burned in (no note text) at native resolution -
/// this is exactly what we send Nano Banana. With no annotations it returns the untouched image.
func renderMarkedImage(_ base: UIImage, annotations: [Annotation]) -> UIImage {
    let format = UIGraphicsImageRendererFormat.default()
    format.scale = base.scale
    format.opaque = true
    let renderer = UIGraphicsImageRenderer(size: base.size, format: format)
    return renderer.image { rctx in
        base.draw(in: CGRect(origin: .zero, size: base.size))
        drawAnnotations(in: rctx.cgContext, size: base.size, annotations: annotations, showNotes: false)
    }
}

// MARK: - Zoomable, drawable canvas
//
// A UIScrollView gives native pinch-zoom + PAN (two fingers). A one-finger pan on the overlay draws
// a new circle (on empty space) or repositions an existing one; a tap edits a circle's note. Because
// the scroll view's own pan requires two fingers, one-finger drawing and two-finger pan/zoom never
// fight for the same touch.

private final class AnnotationOverlayView: UIView {
    var annotations: [Annotation] = []
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isOpaque = false
        contentMode = .redraw
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        drawAnnotations(in: ctx, size: bounds.size, annotations: annotations, showNotes: true)
    }
}

private final class LayoutScrollView: UIScrollView {
    var onLayout: ((CGSize) -> Void)?
    override func layoutSubviews() {
        super.layoutSubviews()
        onLayout?(bounds.size)
    }
}

struct AnnotationCanvas: UIViewRepresentable {
    @ObservedObject var store: AnnotationStore
    let image: UIImage
    var onRequestEdit: (Int, Bool) -> Void      // (index, isNewlyDrawn)

    func makeCoordinator() -> Coordinator { Coordinator(store: store, image: image, onRequestEdit: onRequestEdit) }

    func makeUIView(context: Context) -> UIScrollView { context.coordinator.scrollView }

    func updateUIView(_ uiView: UIScrollView, context: Context) {
        // Reflect external store changes (note text edits, deletes, renumbering).
        context.coordinator.onRequestEdit = onRequestEdit
        context.coordinator.overlay.annotations = store.annotations
        context.coordinator.overlay.setNeedsDisplay()
    }

    final class Coordinator: NSObject, UIScrollViewDelegate {
        let store: AnnotationStore
        let image: UIImage
        var onRequestEdit: (Int, Bool) -> Void

        fileprivate let scrollView = LayoutScrollView()
        let contentView = UIView()
        let imageView = UIImageView()
        fileprivate let overlay = AnnotationOverlayView()

        private var lastBoundsSize: CGSize = .zero
        private var drawStart: CGPoint?
        private var activeDrawIndex: Int?
        private var activeMoveIndex: Int?
        private var lastPoint: CGPoint = .zero

        init(store: AnnotationStore, image: UIImage, onRequestEdit: @escaping (Int, Bool) -> Void) {
            self.store = store; self.image = image; self.onRequestEdit = onRequestEdit
            super.init()
            configure()
        }

        private func configure() {
            scrollView.delegate = self
            scrollView.minimumZoomScale = 1
            scrollView.maximumZoomScale = 4
            scrollView.showsHorizontalScrollIndicator = false
            scrollView.showsVerticalScrollIndicator = false
            scrollView.bouncesZoom = true
            scrollView.backgroundColor = .clear
            scrollView.delaysContentTouches = false
            scrollView.panGestureRecognizer.minimumNumberOfTouches = 2   // two-finger pan; one finger draws
            scrollView.onLayout = { [weak self] size in self?.layout(for: size) }

            imageView.image = image
            imageView.contentMode = .scaleAspectFit
            contentView.addSubview(imageView)
            contentView.addSubview(overlay)
            scrollView.addSubview(contentView)

            overlay.isUserInteractionEnabled = true
            let draw = UIPanGestureRecognizer(target: self, action: #selector(handleDraw(_:)))
            draw.maximumNumberOfTouches = 1
            overlay.addGestureRecognizer(draw)
            let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
            overlay.addGestureRecognizer(tap)
        }

        // Fit the image to the viewport whenever the viewport size changes (initial layout, rotation).
        private func layout(for size: CGSize) {
            guard size.width > 0, size.height > 0, size != lastBoundsSize else { return }
            lastBoundsSize = size
            scrollView.zoomScale = 1
            let fit = Self.aspectFit(imageSize: image.size, in: size)
            contentView.frame = CGRect(origin: .zero, size: fit)
            imageView.frame = contentView.bounds
            overlay.frame = contentView.bounds
            scrollView.contentSize = fit
            centerContent()
            overlay.setNeedsDisplay()
        }

        private func centerContent() {
            let b = scrollView.bounds.size
            let c = scrollView.contentSize
            let x = max(0, (b.width - c.width) / 2)
            let y = max(0, (b.height - c.height) / 2)
            scrollView.contentInset = UIEdgeInsets(top: y, left: x, bottom: y, right: x)
        }

        func viewForZooming(in scrollView: UIScrollView) -> UIView? { contentView }
        func scrollViewDidZoom(_ scrollView: UIScrollView) { centerContent() }

        private static func aspectFit(imageSize: CGSize, in bounds: CGSize) -> CGSize {
            guard imageSize.width > 0, imageSize.height > 0 else { return bounds }
            let scale = min(bounds.width / imageSize.width, bounds.height / imageSize.height)
            return CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        }

        private func redraw() {
            overlay.annotations = store.annotations
            overlay.setNeedsDisplay()
        }

        private func hitCircle(at p: CGPoint) -> Int? {
            let w = overlay.bounds.width, h = overlay.bounds.height
            guard w > 0, h > 0 else { return nil }
            let grab = max(12, w * 0.030)
            for i in store.annotations.indices.reversed() {
                let a = store.annotations[i].rect
                let r = CGRect(x: a.minX * w, y: a.minY * h, width: a.width * w, height: a.height * h)
                    .insetBy(dx: -grab, dy: -grab)
                if r.contains(p) { return i }
            }
            return nil
        }

        private func normalized(_ r: CGRect, _ w: CGFloat, _ h: CGFloat) -> CGRect {
            CGRect(x: r.minX / w, y: r.minY / h, width: r.width / w, height: r.height / h)
        }

        @objc private func handleDraw(_ g: UIPanGestureRecognizer) {
            let p = g.location(in: overlay)
            let w = overlay.bounds.width, h = overlay.bounds.height
            guard w > 0, h > 0 else { return }
            switch g.state {
            case .began:
                if let idx = hitCircle(at: p) {
                    activeMoveIndex = idx; lastPoint = p
                } else {
                    drawStart = p
                    store.annotations.append(Annotation(rect: normalized(CGRect(x: p.x, y: p.y, width: 1, height: 1), w, h)))
                    activeDrawIndex = store.annotations.count - 1
                }
                redraw()
            case .changed:
                if let idx = activeMoveIndex, store.annotations.indices.contains(idx) {
                    store.annotations[idx].rect.origin.x += (p.x - lastPoint.x) / w
                    store.annotations[idx].rect.origin.y += (p.y - lastPoint.y) / h
                    lastPoint = p
                } else if let idx = activeDrawIndex, let s = drawStart, store.annotations.indices.contains(idx) {
                    let r = CGRect(x: min(s.x, p.x), y: min(s.y, p.y), width: abs(p.x - s.x), height: abs(p.y - s.y))
                    store.annotations[idx].rect = normalized(r, w, h)
                }
                redraw()
            case .ended, .cancelled, .failed:
                if let idx = activeDrawIndex, store.annotations.indices.contains(idx) {
                    let r = store.annotations[idx].rect
                    if r.width * w < 24 || r.height * h < 24 {
                        store.annotations.remove(at: idx)          // a stray tap-sized circle: discard
                    } else {
                        onRequestEdit(idx, true)                   // new circle -> open its note immediately
                    }
                }
                activeDrawIndex = nil; activeMoveIndex = nil; drawStart = nil
                redraw()
            default: break
            }
        }

        @objc private func handleTap(_ g: UITapGestureRecognizer) {
            if let idx = hitCircle(at: g.location(in: overlay)) { onRequestEdit(idx, false) }
        }
    }
}

// MARK: - Full-screen editor

struct FlyerAnnotationView: View {
    @StateObject private var store: AnnotationStore
    private let image: UIImage
    private let sourceImageData: Data
    private let onApply: (_ marked: Data, _ instruction: String, _ annotated: Bool, _ draft: AnnotationDraft) -> Void
    private let onCancel: () -> Void

    @State private var showNoteEditor = false
    @State private var editingIndex: Int?
    @State private var editingIsNew = false
    @State private var noteDraft = ""

    init(request: AnnotationEditorRequest,
         onApply: @escaping (_ marked: Data, _ instruction: String, _ annotated: Bool, _ draft: AnnotationDraft) -> Void,
         onCancel: @escaping () -> Void) {
        self.image = UIImage(data: request.imageData) ?? UIImage()
        self.sourceImageData = request.imageData
        self.onApply = onApply
        self.onCancel = onCancel
        let s = AnnotationStore()
        if let seed = request.seed { s.annotations = seed.annotations; s.generalNote = seed.generalNote }
        _store = StateObject(wrappedValue: s)
    }

    private var canApply: Bool {
        !store.annotations.isEmpty || !store.generalNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                AnnotationCanvas(store: store, image: image, onRequestEdit: openEditor)
                    .background(Color.black)
                    .overlay(alignment: .top) { if store.annotations.isEmpty { hint } }
                bottomBar
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Mark up to edit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel", action: onCancel) }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Apply", action: apply).fontWeight(.semibold).disabled(!canApply)
                }
            }
            .alert(editingIsNew ? "Add a note" : "Edit note", isPresented: $showNoteEditor) {
                TextField("What should change here?", text: $noteDraft)
                Button("Save", action: commitNote)
                if !editingIsNew { Button("Delete", role: .destructive, action: deleteEditing) }
                Button("Cancel", role: .cancel, action: cancelNote)
            } message: {
                Text(editingIndex.map { "Circle \($0 + 1)" } ?? "")
            }
        }
    }

    private var hint: some View {
        Text("Drag to circle an area · pinch to zoom")
            .font(FGTypography.caption)
            .foregroundColor(.white)
            .padding(.horizontal, FGSpacing.sm).padding(.vertical, FGSpacing.xs)
            .background(Capsule().fill(Color.black.opacity(0.55)))
            .padding(.top, FGSpacing.sm)
    }

    private var bottomBar: some View {
        VStack(spacing: FGSpacing.xs) {
            HStack(spacing: FGSpacing.xs) {
                Image(systemName: "pencil.and.outline").foregroundColor(FGColors.accentSecondary)
                TextField("Anything about the whole flyer? (optional)", text: $store.generalNote, axis: .vertical)
                    .lineLimit(1...3)
                    .font(FGTypography.bodySmall)
                    .foregroundColor(FGColors.textPrimary)
                if !store.annotations.isEmpty {
                    Text("\(store.annotations.count)")
                        .font(FGTypography.captionBold).foregroundColor(FGColors.textOnAccent)
                        .frame(minWidth: 22, minHeight: 22)
                        .background(Circle().fill(FGColors.accentPrimary))
                }
            }
            .padding(.horizontal, FGSpacing.sm).padding(.vertical, FGSpacing.xs)
            .background(FGColors.surfaceDefault).clipShape(RoundedRectangle(cornerRadius: FGSpacing.inputRadius))
        }
        .padding(FGSpacing.sm)
        .background(FGColors.backgroundSecondary.ignoresSafeArea(edges: .bottom))
    }

    // MARK: Note editing

    private func openEditor(_ index: Int, _ isNew: Bool) {
        editingIndex = index
        editingIsNew = isNew
        noteDraft = store.annotations.indices.contains(index) ? store.annotations[index].note : ""
        showNoteEditor = true
    }

    private func commitNote() {
        guard let idx = editingIndex, store.annotations.indices.contains(idx) else { return }
        let t = noteDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.isEmpty { store.annotations.remove(at: idx) }       // no instruction -> no circle
        else { store.annotations[idx].note = t }
        editingIndex = nil
    }

    private func deleteEditing() {
        guard let idx = editingIndex, store.annotations.indices.contains(idx) else { return }
        store.annotations.remove(at: idx)                        // remaining circles renumber by position
        editingIndex = nil
    }

    private func cancelNote() {
        if editingIsNew, let idx = editingIndex, store.annotations.indices.contains(idx) {
            store.annotations.remove(at: idx)                    // discard a just-drawn circle left noteless
        }
        editingIndex = nil
    }

    // MARK: Apply

    /// The numbered instruction list plus, if present, a trailing whole-flyer line. Kept in lockstep
    /// with the flattened image's circle numbers (both derive from `store.annotations` order).
    private func compiledInstruction() -> String {
        var body = store.annotations.enumerated()
            .map { "\($0.offset + 1). \($0.element.note.trimmingCharacters(in: .whitespacesAndNewlines))" }
            .joined(separator: "\n")
        let general = store.generalNote.trimmingCharacters(in: .whitespacesAndNewlines)
        if !general.isEmpty {
            if !body.isEmpty { body += "\n\n" }
            body += "Also, across the whole flyer: \(general)"
        }
        return body
    }

    private func apply() {
        let annotated = !store.annotations.isEmpty
        let marked = renderMarkedImage(image, annotations: annotated ? store.annotations : [])
        let jpeg = marked.jpegData(compressionQuality: 0.92) ?? sourceImageData
        let draft = AnnotationDraft(sourceImageData: sourceImageData,
                                    annotations: store.annotations, generalNote: store.generalNote)
        onApply(jpeg, compiledInstruction(), annotated, draft)
    }
}
