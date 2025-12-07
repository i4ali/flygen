import Foundation

struct OutputSettings: Codable, Equatable {
    var aspectRatio: AspectRatio = .portrait
    var quality: String = "hd"
    var model: String = "nano-banana"
}
