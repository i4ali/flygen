import Foundation
import SwiftData

@Model
final class UserProfile {
    var id: UUID = UUID()
    var credits: Int = 3
    var isPremium: Bool = false
    var premiumExpiresAt: Date?
    var createdAt: Date = Date()
    var lastSyncedAt: Date = Date()

    init() {
        self.id = UUID()
        self.credits = 3
        self.isPremium = false
        self.premiumExpiresAt = nil
        self.createdAt = Date()
        self.lastSyncedAt = Date()
    }
}
