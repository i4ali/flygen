import Foundation

struct FlyerTemplate: Identifiable {
    let id: String
    let name: String
    let category: FlyerCategory
    let textContent: TextContent
    let colors: ColorSettings
    let visuals: VisualSettings
    let output: OutputSettings
    let previewDescription: String

    /// Creates a FlyerProject from this template
    func toProject() -> FlyerProject {
        var project = FlyerProject(category: category)
        project.textContent = textContent
        project.colors = colors
        project.visuals = visuals
        project.output = output
        return project
    }
}
