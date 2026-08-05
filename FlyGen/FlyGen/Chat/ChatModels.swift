import Foundation

// MARK: - Request (mirrors engine/app.py ChatIn; nil fields are omitted on encode)

struct ChatRequest: Encodable {
    var message: String?
    var action: String?
    var stage: String?                  // "design" => answering the design brief's must-fix questions
    var brief: ExtractedBriefDTO?
    var answers: [String: String]?
    var instruction: String?
    var prior_image_b64: String?
    var reference_image_b64: String?    // uploaded flyer to reuse; edited in place using `message`
    var aspect_ratio: String?
    var field_overrides: [String: String]?
    var decision_overrides: [String: String]?
    var user_photos_b64: [String]?      // uploaded source photos, sent on the approve turn
    var selected_elements: [String]?    // chosen creative elements (their what-text), sent on approve
    var annotated: Bool?                // marked-up flyer (numbered circles) => engine uses the annotated-edit prompt
    var language: String?               // target flyer language code; stamped centrally in run(...)
    var qr: QRSettingsDTO?              // standalone QR state, echoed on every action; stamped centrally in run(...)
}

// MARK: - QR code (standalone wire state; not part of the brief)

/// Mirrors the engine's `qr` object. Codable both ways: encoded onto every request, decoded from
/// the `qr` SSE event. No UI - the QR arrives baked into concept images.
struct QRSettingsDTO: Codable, Equatable {
    var enabled: Bool?
    var kind: String?
    var value: String?
    var corner: String?
}

/// A proactive QR offer from the engine (the brain proposed a QR on an otherwise-ready draft).
/// `text` is the card headline; kind/value/corner build the QRSettingsDTO when the user taps Yes.
struct QROfferDTO: Decodable, Equatable {
    let kind: String?
    let value: String?
    let corner: String?
    let text: String
}

// MARK: - parsed_fields payload (round-trips as `brief`)

struct ExtractedBriefDTO: Codable, Equatable {
    var category: String?
    var headline: String?
    var subheadline: String?
    var body_text: String?
    var date: String?
    var time: String?
    var venue_name: String?
    var address: String?
    var price: String?
    var discount_text: String?
    var cta_text: String?
    var phone: String?
    var email: String?
    var website: String?
    var social_handle: String?
    var additional_info: [String]?     // answers with no dedicated slot — must round-trip back
    var purpose: String?
    var destination: String?
    var field_sources: [String: String]?
    var photo_suggestion: String?      // brain's "add a photo of X" nudge; shown once per flyer
    // The APPROVED design, stashed onto the brief by the engine at generation time (brief_state
    // event) and echoed back on every later turn - so a refine rebuilds the approved look
    // (palette/style/mood/aspect + creative elements) instead of compile-time defaults.
    var decisions: [BriefDecisionDTO]?
    var creative_elements: [BriefElementDTO]?

    /// Non-empty content fields in display order (category first), with their source.
    var displayFields: [(key: String, value: String, source: String)] {
        let pairs: [(String, String?)] = [
            ("category", category), ("headline", headline), ("subheadline", subheadline),
            ("body_text", body_text), ("date", date), ("time", time),
            ("venue_name", venue_name), ("address", address), ("price", price),
            ("discount_text", discount_text), ("cta_text", cta_text),
            ("phone", phone), ("email", email), ("website", website),
            ("social_handle", social_handle),
        ]
        var out = pairs.compactMap { key, value -> (key: String, value: String, source: String)? in
            guard let v = value, !v.isEmpty else { return nil }
            return (key, v, field_sources?[key] ?? "inferred")
        }
        // Captured extras (e.g. "experience required: none") — surfaced so the user sees them.
        for item in (additional_info ?? []) where !item.isEmpty {
            out.append((key: "extra", value: item, source: "stated"))
        }
        return out
    }
}

/// One approved design decision (key: format | palette | visual_style | mood | quality).
/// Opaque to the UI - it only needs to survive the round-trip.
struct BriefDecisionDTO: Codable, Equatable { var key: String; var value: String }
/// One approved creative element; rides the brief like decisions do.
struct BriefElementDTO: Codable, Equatable { var what: String }

// MARK: - questions payload

struct QuestionSetDTO: Decodable { let questions: [QuestionDTO]; let stage: String? }
struct FormatOptionDTO: Decodable, Equatable { let value: String; let label: String }
struct QuestionDTO: Decodable, Identifiable {
    let field: String
    let text: String
    var options: [FormatOptionDTO]?     // when present, render a labeled picker (e.g. size)
    var id: String { field }
}

// MARK: - design_brief payload

struct DesignBriefDTO: Decodable {
    let notes: String
    let checklist: [String]
    let recommendations: [String]
}

// MARK: - review payload

struct ReviewProposalDTO: Decodable {
    let fields: [FieldProposalDTO]
    let decisions: [DecisionProposalDTO]
    var creative_elements: [CreativeProposalDTO]?
    let plan: DesignBriefDTO?
}
struct FieldProposalDTO: Decodable, Identifiable {
    let key: String; let value: String; let source: String
    var warning: String?                     // set when the value needs attention (e.g. a malformed URL)
    var id: String { key }
}
struct DecisionProposalDTO: Decodable, Identifiable {
    let key: String; let label: String; let value: String
    let options: [String]; let reason: String
    var option_labels: [String: String]?     // value -> human label (e.g. size platform hints)
    var supported: Bool?                     // false => off-vocabulary value (not a standard option)
    var id: String { key }
}
struct CreativeProposalDTO: Decodable, Identifiable {
    let what: String
    var why: String?
    var sensitivity: String?                 // "safe" => pre-selected; "sensitive" => opt-in
    var selected: Bool?                      // engine default (safe on, sensitive off)
    var id: String { what }
}

// MARK: - concepts | refined | resized payload

struct ConceptDTO: Decodable, Identifiable {
    let version_id: String
    let image_base64: String?
    let error: String?
    var id: String { version_id }
    var imageData: Data? { image_base64.flatMap { Data(base64Encoded: $0) } }
}

// MARK: - SSE events

enum SSEEvent {
    case parsedFields(ExtractedBriefDTO)
    case briefState(ExtractedBriefDTO)      // silent brief update (approved design); stored, no bubble
    case questions([QuestionDTO], String)   // payload + stage ("gaps" | "design")
    case designBrief(DesignBriefDTO)
    case review(ReviewProposalDTO)
    case concepts([ConceptDTO])
    case refined(ConceptDTO)
    case resized(ConceptDTO)
    case qr(QRSettingsDTO)                   // updated QR state; stored and echoed, no UI
    case qrOffer(QROfferDTO)                 // proactive "add a QR?" offer -> tappable Yes/No card
    case note(String)                       // a conversational assistant line
    case error(String)
    case unknown(String)

    static func decode(event: String, data: Data) -> SSEEvent {
        let dec = JSONDecoder()
        do {
            switch event {
            case "parsed_fields": return .parsedFields(try dec.decode(ExtractedBriefDTO.self, from: data))
            case "brief_state":   return .briefState(try dec.decode(ExtractedBriefDTO.self, from: data))
            case "questions":
                let qs = try dec.decode(QuestionSetDTO.self, from: data)
                return .questions(qs.questions, qs.stage ?? "gaps")
            case "note":
                let msg = (try? dec.decode(String.self, from: data)) ?? String(data: data, encoding: .utf8) ?? ""
                return .note(msg)
            case "design_brief":  return .designBrief(try dec.decode(DesignBriefDTO.self, from: data))
            case "review":        return .review(try dec.decode(ReviewProposalDTO.self, from: data))
            case "concepts":      return .concepts(try dec.decode([ConceptDTO].self, from: data))
            case "refined":       return .refined(try dec.decode(ConceptDTO.self, from: data))
            case "resized":       return .resized(try dec.decode(ConceptDTO.self, from: data))
            case "qr":            return .qr(try dec.decode(QRSettingsDTO.self, from: data))
            case "qr_offer":      return .qrOffer(try dec.decode(QROfferDTO.self, from: data))
            case "error":
                let msg = (try? dec.decode(String.self, from: data)) ?? String(data: data, encoding: .utf8) ?? "error"
                return .error(msg)
            default: return .unknown(event)
            }
        } catch {
            return .error("decode failed for \(event): \(error.localizedDescription)")
        }
    }
}
