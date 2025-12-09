import Foundation
import SwiftData

@Model
final class UserProfile {
    var id: UUID = UUID()
    var credits: Int = 10
    var isPremium: Bool = false
    var premiumExpiresAt: Date?
    var createdAt: Date = Date()
    var lastSyncedAt: Date = Date()

    init() {
        self.id = UUID()
        self.credits = 10
        self.isPremium = false
        self.premiumExpiresAt = nil
        self.createdAt = Date()
        self.lastSyncedAt = Date()
    }
}
