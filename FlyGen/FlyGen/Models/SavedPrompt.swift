import Foundation
import SwiftData

/// A prompt the user saved to reuse later. Mirrors `SavedFlyer`'s CloudKit-safe shape
/// (all non-optional stored properties have defaults + a no-arg init).
@Model
final class SavedPrompt {
    var id: UUID = UUID()
    var title: String = ""
    var text: String = ""
    var categoryRawValue: String = FlyerCategory.announcement.rawValue
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    init() {}   // required for CloudKit

    init(title: String, text: String, category: FlyerCategory) {
        self.id = UUID()
        self.title = title
        self.text = text
        self.categoryRawValue = category.rawValue
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    /// Typed accessor over the CloudKit-safe raw string.
    var category: FlyerCategory {
        get { FlyerCategory(rawValue: categoryRawValue) ?? .announcement }
        set { categoryRawValue = newValue.rawValue }
    }
}
