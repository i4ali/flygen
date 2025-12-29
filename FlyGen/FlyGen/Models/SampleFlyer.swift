import Foundation

/// A sample flyer displayed in the Explore tab that can be used as a starting point
struct SampleFlyer: Identifiable {
    let id: String
    let imageName: String
    let name: String
    let category: FlyerCategory
    let language: FlyerLanguage
    let textContent: TextContent
    let colors: ColorSettings
    let visuals: VisualSettings
    let output: OutputSettings
    let targetAudience: String?
    let specialInstructions: String?

    init(
        id: String,
        imageName: String,
        name: String,
        category: FlyerCategory,
        language: FlyerLanguage = .english,
        textContent: TextContent,
        colors: ColorSettings,
        visuals: VisualSettings,
        output: OutputSettings,
        targetAudience: String? = nil,
        specialInstructions: String? = nil
    ) {
        self.id = id
        self.imageName = imageName
        self.name = name
        self.category = category
        self.language = language
        self.textContent = textContent
        self.colors = colors
        self.visuals = visuals
        self.output = output
        self.targetAudience = targetAudience
        self.specialInstructions = specialInstructions
    }

    /// Creates a FlyerProject from this sample
    func toProject() -> FlyerProject {
        var project = FlyerProject(category: category, language: language)
        project.textContent = textContent
        project.colors = colors
        project.visuals = visuals
        project.output = output
        project.targetAudience = targetAudience
        project.specialInstructions = specialInstructions
        return project
    }
}
