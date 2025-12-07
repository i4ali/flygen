import Foundation

struct VisualSettings: Codable, Equatable {
    var style: VisualStyle = .modernMinimal
    var mood: Mood = .friendly
    var textProminence: TextProminence = .balanced
    var imageryType: ImageryType = .illustrated
    var includeElements: [String] = []
    var avoidElements: [String] = []
}
