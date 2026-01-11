import Foundation

/// Result of building a prompt
struct PromptPackage {
    let mainPrompt: String
    let negativePrompt: String
    let aspectRatio: String
    let model: String
    let quality: String
}

/// Builds optimized prompts from structured FlyerProject data
/// This is the "secret sauce" - ported from Python prompt_builder.py
struct PromptBuilder {
    let project: FlyerProject

    init(project: FlyerProject) {
        self.project = project
    }

    /// Build complete prompt package
    func build() -> PromptPackage {
        return PromptPackage(
            mainPrompt: buildMainPrompt(),
            negativePrompt: buildNegativePrompt(),
            aspectRatio: project.output.aspectRatio.rawValue,
            model: project.output.model,
            quality: project.output.quality
        )
    }

    // MARK: - Main Prompt Construction (14 sections)

    private func buildMainPrompt() -> String {
        var sections: [String] = []

        // 1. Core instruction with category context
        let categoryContext = PromptDescriptors.categoryContext[project.category] ?? "promotional flyer design"
        sections.append("Create a professional high-quality \(categoryContext).")

        // 1.5 Language requirement
        if project.language != .english {
            sections.append("""
                CRITICAL LANGUAGE REQUIREMENT: \(project.language.promptInstruction) \
                You MUST ensure ALL text content appears in the target language. \
                Translate any English or non-target-language text. Do NOT render English text as-is.
                """)
        }

        // 2. Aspect ratio / format
        let aspectInstruction = PromptDescriptors.aspectRatioInstructions[project.output.aspectRatio] ?? "standard flyer proportions"
        sections.append("Format: \(aspectInstruction).")

        // 2.5 Flat design requirement
        sections.append("""
            CRITICAL: Render as a FLAT, full-bleed design that fills the entire canvas edge-to-edge. \
            Do NOT render as a 3D mockup, physical card, paper on a surface, or product photograph. \
            No shadows, no perspective, no depth effects - completely flat 2D design only.
            """)

        // 3. Visual style
        let styleDesc = PromptDescriptors.styleDescriptors[project.visuals.style] ?? "clean professional design"
        sections.append("Visual style: \(styleDesc).")

        // 4. Mood / tone
        let moodDesc = PromptDescriptors.moodDescriptors[project.visuals.mood] ?? "appropriate and engaging mood"
        sections.append("Mood and tone: \(moodDesc).")

        // 5. Color palette
        sections.append(buildColorSection())

        // 6. Text content (only if not in NO_TEXT mode)
        if project.visuals.imageryType != .noText {
            sections.append(buildTextSection())
        } else {
            sections.append("""
                IMPORTANT: Do NOT render any text in this image. \
                Leave clean space for text to be added using external design tools like Canva or Photoshop.
                """)
        }

        // 7. Text prominence (skip for NO_TEXT mode)
        if project.visuals.imageryType != .noText {
            if let prominenceInstruction = PromptDescriptors.textProminenceInstructions[project.visuals.textProminence] {
                sections.append("IMPORTANT: \(prominenceInstruction).")
            }
        }

        // 8. Imagery type
        if let imageryInstruction = PromptDescriptors.imageryTypeInstructions[project.visuals.imageryType] {
            sections.append("Visual elements \(imageryInstruction).")
        }

        // 9. Specific elements to include
        if !project.visuals.includeElements.isEmpty {
            let elements = project.visuals.includeElements.joined(separator: ", ")
            sections.append("Include visual elements such as: \(elements).")
        }

        // 10. Category-specific hints
        let hints = buildCategoryHints()
        if !hints.isEmpty {
            sections.append(hints)
        }

        // 11. Target audience
        if let audience = project.targetAudience, !audience.isEmpty {
            sections.append("Design should appeal to: \(audience).")
        }

        // 12. Special instructions
        if let instructions = project.specialInstructions, !instructions.isEmpty {
            sections.append("Additional requirements: \(instructions).")
        }

        // Note: Logo is no longer mentioned in prompt - it's composited programmatically after generation

        // 13. User photo OR imagery description (mutually exclusive)
        if project.userPhotoData != nil {
            sections.append("""
                CRITICAL USER PHOTO INSTRUCTIONS: A user photo has been provided and MUST be incorporated into the flyer design. \
                Decide the optimal placement and size for the photo based on the overall composition - it could be a hero image, \
                a smaller inset, or integrated into the background. \
                IMPORTANT: Preserve the photo's original structure, subjects, and composition exactly as provided. \
                You may apply color grading, filters, or artistic effects to match the flyer's style (\(project.visuals.style.displayName)) \
                and mood (\(project.visuals.mood.displayName)), but do NOT alter, morph, or change the actual content of the photo. \
                The subjects must remain clearly recognizable and unchanged. \
                Do NOT crop out important subjects from the photo.
                """)
        } else if let imageryDesc = project.imageryDescription, !imageryDesc.isEmpty {
            // For food/restaurant category, enforce photorealistic food photography for ALL dishes
            if project.category == .restaurantFood {
                sections.append("""
                    FOOD IMAGERY - CRITICAL REQUIREMENTS: \
                    You MUST show ALL of these dishes in the flyer: \(imageryDesc). \
                    IMPORTANT: Every single dish listed must be clearly visible and separately identifiable in the image. \
                    All food images MUST be photorealistic - real photographs taken with a professional camera. \
                    NOT illustrations, NOT cartoons, NOT digital art, NOT vector graphics, NOT painted style. \
                    Use consistent photographic style across ALL dishes: professional food photography, \
                    natural lighting, realistic textures, shallow depth of field, appetizing presentation. \
                    Arrange all dishes attractively within the composition - use a grid, collage, or artistic arrangement \
                    so each dish is clearly showcased. The food should look delicious, fresh, and ready to eat.
                    """)
            } else {
                sections.append("""
                    IMAGERY GENERATION: Generate custom visual imagery based on this description: "\(imageryDesc)". \
                    The generated imagery should match the flyer's style (\(project.visuals.style.displayName)), \
                    colors, and mood (\(project.visuals.mood.displayName)). \
                    Integrate this imagery as a key visual element within the composition.
                    """)
            }
        }

        // 15. Quality reminders (conditional based on NO_TEXT mode)
        if project.visuals.imageryType != .noText {
            sections.append("""
                CRITICAL TEXT REQUIREMENTS: \
                All text must be spelled EXACTLY as specified above - double-check every letter. \
                Do not paraphrase, abbreviate, or modify any text. \
                Ensure all text is crisp, clear, and perfectly legible. \
                Professional print-ready quality. \
                Visually striking and memorable design. \
                Balanced composition with clear visual hierarchy.
                """)
        } else {
            sections.append("""
                CRITICAL: This design must have NO TEXT whatsoever. \
                No letters, words, numbers, or written content of any kind. \
                Create empty space in key areas where text can be overlaid later. \
                Professional print-ready quality. \
                Visually striking and memorable design. \
                Balanced composition suitable for text overlay.
                """)
        }

        return sections.filter { !$0.isEmpty }.joined(separator: " ")
    }

    // MARK: - Color Section

    private func buildColorSection() -> String {
        var parts: [String] = []

        // Preset palette
        if let paletteDesc = PromptDescriptors.colorPaletteDescriptors[project.colors.preset], !paletteDesc.isEmpty {
            parts.append("Color scheme: \(paletteDesc).")
        }

        // Specific colors
        var colorSpecs: [String] = []
        if let primary = project.colors.primaryColor, !primary.isEmpty {
            colorSpecs.append("primary: \(primary)")
        }
        if let secondary = project.colors.secondaryColor, !secondary.isEmpty {
            colorSpecs.append("secondary: \(secondary)")
        }
        if let accent = project.colors.accentColor, !accent.isEmpty {
            colorSpecs.append("accent: \(accent)")
        }
        if !colorSpecs.isEmpty {
            parts.append("Specific colors: \(colorSpecs.joined(separator: ", ")).")
        }

        // Background
        if let gradientColors = project.colors.gradientColors, !gradientColors.isEmpty {
            let gradient = gradientColors.joined(separator: " to ")
            parts.append("Background: gradient from \(gradient).")
        } else if let bgColor = project.colors.backgroundColor, !bgColor.isEmpty {
            let bgTypeDesc = PromptDescriptors.backgroundDescriptors[project.colors.backgroundType] ?? ""
            parts.append("Background: \(bgColor) \(bgTypeDesc).")
        } else {
            if let bgDesc = PromptDescriptors.backgroundDescriptors[project.colors.backgroundType] {
                parts.append("Background: \(bgDesc).")
            }
        }

        return parts.joined(separator: " ")
    }

    // MARK: - Text Section with Spelling Emphasis

    private func buildTextSection() -> String {
        let text = project.textContent
        var parts: [String] = []

        // Add translation reminder for non-English languages
        if project.language != .english {
            parts.append("""
                IMPORTANT: All text below MUST appear in \(project.language.displayName). \
                If any text is in English or another language, translate it. \
                If text is already in the target language, use it as-is.
                """)
        }

        parts.append("TEXT CONTENT - CRITICAL: Spell ALL text EXACTLY as shown, letter by letter:")

        // Headline - most important, with character-by-character spelling
        if !text.headline.isEmpty {
            let spelled = spellOut(text.headline.uppercased())
            parts.append("""
                MAIN HEADLINE must read EXACTLY: "\(text.headline)" \
                (SPELLING: \(spelled)) - \
                this should be the most visually dominant text element. \
                Double-check every letter is correct.
                """)
        }

        // Subheadline
        if let subheadline = text.subheadline, !subheadline.isEmpty {
            if subheadline.split(separator: " ").count > 8 {
                parts.append("Secondary headline (display across multiple lines if needed):")
                for chunk in chunkText(subheadline, maxWords: 5) {
                    let spelled = spellOut(chunk)
                    parts.append("  Line: \"\(chunk)\" (SPELLING: \(spelled)).")
                }
            } else {
                let spelled = spellOut(subheadline)
                parts.append("Secondary headline must read EXACTLY: \"\(subheadline)\" (SPELLING: \(spelled)).")
            }
        }

        // Body text - chunk long text for better accuracy
        if let bodyText = text.bodyText, !bodyText.isEmpty {
            if bodyText.split(separator: " ").count > 10 {
                parts.append("Body content (display across multiple lines/sections):")
                for chunk in chunkText(bodyText, maxWords: 8) {
                    let spelled = spellOut(chunk)
                    parts.append("  Section: \"\(chunk)\" (SPELLING: \(spelled)).")
                }
            } else {
                let spelled = spellOut(bodyText)
                parts.append("Body text must read EXACTLY: \"\(bodyText)\" (SPELLING: \(spelled)).")
            }
        }

        // Date and time
        if let date = text.date, !date.isEmpty, let time = text.time, !time.isEmpty {
            let combined = "\(date) | \(time)"
            let spelled = spellOut(combined)
            parts.append("Date/time must read EXACTLY: \"\(combined)\" (SPELLING: \(spelled)).")
        } else if let date = text.date, !date.isEmpty {
            let spelled = spellOut(date)
            parts.append("Date must read EXACTLY: \"\(date)\" (SPELLING: \(spelled)).")
        } else if let time = text.time, !time.isEmpty {
            let spelled = spellOut(time)
            parts.append("Time must read EXACTLY: \"\(time)\" (SPELLING: \(spelled)).")
        }

        // Location - simplify address
        var address = text.address ?? ""
        for suffix in [", United States", ", USA", ", US"] {
            if address.hasSuffix(suffix) {
                address = String(address.dropLast(suffix.count))
                break
            }
        }

        // Location - handle RTL languages specially to avoid bidirectional text confusion
        if let venueName = text.venueName, !venueName.isEmpty, !address.isEmpty {
            if project.language == .arabic || project.language == .urdu {
                // Separate lines for RTL to avoid mixing directions
                let spelledVenue = spellOut(venueName)
                parts.append("Venue name must read EXACTLY: \"\(venueName)\" (SPELLING: \(spelledVenue)).")
                let spelledAddr = spellOut(address)
                parts.append("Address on separate line must read EXACTLY: \"\(address)\" (SPELLING: \(spelledAddr)).")
            } else {
                let location = "\(venueName) - \(address)"
                let spelled = spellOut(location)
                parts.append("Location must read EXACTLY: \"\(location)\" (SPELLING: \(spelled)).")
            }
        } else if let venueName = text.venueName, !venueName.isEmpty {
            let spelled = spellOut(venueName)
            parts.append("Venue must read EXACTLY: \"\(venueName)\" (SPELLING: \(spelled)).")
        } else if !address.isEmpty {
            let spelled = spellOut(address)
            parts.append("Address must read EXACTLY: \"\(address)\" (SPELLING: \(spelled)).")
        }

        // Price / Discount
        if let discountText = text.discountText, !discountText.isEmpty {
            let spelled = spellOut(discountText)
            parts.append("""
                Discount/offer must read EXACTLY: "\(discountText)" (SPELLING: \(spelled)) - \
                make this eye-catching and prominent.
                """)
        } else if let price = text.price, !price.isEmpty {
            let spelled = spellOut(price)
            parts.append("Price must read EXACTLY: \"\(price)\" (SPELLING: \(spelled)).")
        }

        // CTA
        if let cta = text.ctaText, !cta.isEmpty {
            let spelled = spellOut(cta)
            parts.append("Call-to-action must read EXACTLY: \"\(cta)\" (SPELLING: \(spelled)).")
        }

        // Contact info
        if let phone = text.phone, !phone.isEmpty {
            let spelled = spellOut(phone)
            parts.append("Phone must read EXACTLY: \"\(phone)\" (SPELLING: \(spelled)).")
        }
        if let email = text.email, !email.isEmpty {
            let spelled = spellOut(email)
            parts.append("Email must read EXACTLY: \"\(email)\" (SPELLING: \(spelled)).")
        }
        if let website = text.website, !website.isEmpty {
            let spelled = spellOut(website)
            parts.append("Website must read EXACTLY: \"\(website)\" (SPELLING: \(spelled)).")
        }
        if let social = text.socialHandle, !social.isEmpty {
            let spelled = spellOut(social)
            parts.append("Social handle must read EXACTLY: \"\(social)\" (SPELLING: \(spelled)).")
        }

        // Additional info
        if let additionalInfo = text.additionalInfo {
            for info in additionalInfo {
                let spelled = spellOut(info)
                parts.append("Additional detail must read EXACTLY: \"\(info)\" (SPELLING: \(spelled)).")
            }
        }

        // Fine print
        if let finePrint = text.finePrint, !finePrint.isEmpty {
            if finePrint.split(separator: " ").count > 8 {
                parts.append("Fine print (can span multiple lines):")
                for chunk in chunkText(finePrint, maxWords: 5) {
                    let spelled = spellOut(chunk)
                    parts.append("  Line: \"\(chunk)\" (SPELLING: \(spelled)).")
                }
            } else {
                let spelled = spellOut(finePrint)
                parts.append("Fine print must read EXACTLY: \"\(finePrint)\" (SPELLING: \(spelled)).")
            }
        }

        return parts.joined(separator: " ")
    }

    // MARK: - Category Hints

    private func buildCategoryHints() -> String {
        var hints: [String] = []

        // Sale/promo specific
        if project.category == .salePromo {
            if let discount = project.textContent.discountText, !discount.isEmpty {
                hints.append("Ensure discount/offer is immediately visible and attention-grabbing.")
            }
        }

        // Event specific
        if project.category == .event {
            if let date = project.textContent.date, !date.isEmpty {
                hints.append("Date and time should be clearly visible and easy to find.")
            }
        }

        // Grand opening specific
        if project.category == .grandOpening {
            hints.append("Convey excitement and celebration of a new beginning.")
        }

        return hints.joined(separator: " ")
    }

    // MARK: - Negative Prompt

    private func buildNegativePrompt() -> String {
        var negatives = NegativePrompts.forCategory(project.category)

        // Add user-specified avoidances
        negatives.append(contentsOf: project.visuals.avoidElements)

        return negatives.joined(separator: ", ")
    }

    // MARK: - Helper Methods

    /// Spell out text character by character for emphasis
    private func spellOut(_ text: String) -> String {
        text.map { String($0) }.joined(separator: " ")
    }

    /// Split text into smaller chunks for better spelling accuracy
    private func chunkText(_ text: String, maxWords: Int) -> [String] {
        let words = text.split(separator: " ").map { String($0) }
        var chunks: [String] = []
        var currentChunk: [String] = []

        for word in words {
            currentChunk.append(word)
            if currentChunk.count >= maxWords {
                chunks.append(currentChunk.joined(separator: " "))
                currentChunk = []
            }
        }

        if !currentChunk.isEmpty {
            chunks.append(currentChunk.joined(separator: " "))
        }

        return chunks
    }
}
