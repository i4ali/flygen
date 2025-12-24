import CloudKit
import SwiftUI

@MainActor
class CloudKitService: ObservableObject {
    @Published var accountStatus: CKAccountStatus = .couldNotDetermine
    @Published var userRecordID: CKRecord.ID?
    @Published var isSignedIn: Bool = false
    @Published var isChecking: Bool = true
    @Published var isSyncing: Bool = false

    private let container = CKContainer(identifier: "iCloud.com.flygen.app")
    private let recordType = "UserCredits"
    private let creditsKey = "credits"
    private let creditsRecordName = "user-credits-record"  // Fixed ID for all devices
    private var creditsRecordID: CKRecord.ID?

    // Preferences
    private let preferencesRecordType = "UserPreferences"
    private let preferredCategoriesKey = "preferredCategories"
    private let preferencesRecordName = "user-preferences-record"

    init() {
        Task {
            await checkAccountStatus()
            setupAccountChangeNotification()
        }
    }

    func checkAccountStatus() async {
        isChecking = true
        do {
            let status = try await container.accountStatus()
            accountStatus = status
            isSignedIn = (status == .available)

            if isSignedIn {
                await fetchUserRecordID()
            }
        } catch {
            print("CloudKit account status error: \(error.localizedDescription)")
            accountStatus = .couldNotDetermine
            isSignedIn = false
        }
        isChecking = false
    }

    private func fetchUserRecordID() async {
        do {
            let recordID = try await container.userRecordID()
            userRecordID = recordID
        } catch {
            print("CloudKit user record ID error: \(error.localizedDescription)")
        }
    }

    private func setupAccountChangeNotification() {
        NotificationCenter.default.addObserver(
            forName: .CKAccountChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.checkAccountStatus()
            }
        }
    }

    var statusMessage: String {
        switch accountStatus {
        case .available:
            return "iCloud is available"
        case .noAccount:
            return "No iCloud account found. Please sign in to iCloud in Settings."
        case .restricted:
            return "iCloud access is restricted on this device."
        case .couldNotDetermine:
            return "Could not determine iCloud status."
        case .temporarilyUnavailable:
            return "iCloud is temporarily unavailable. Please try again later."
        @unknown default:
            return "Unknown iCloud status."
        }
    }

    // MARK: - Credit Sync Methods

    /// Fetches credits from CloudKit using deterministic record ID
    /// - Returns: The credits stored in CloudKit, or nil if no record exists
    func fetchCredits() async -> Int? {
        guard isSignedIn else { return nil }

        let database = container.privateCloudDatabase
        let recordID = CKRecord.ID(recordName: creditsRecordName)

        do {
            let record = try await database.record(for: recordID)
            creditsRecordID = record.recordID
            return record[creditsKey] as? Int
        } catch {
            // Record doesn't exist yet
            print("CloudKit fetchCredits: No record found")
            return nil
        }
    }

    /// Saves credits to CloudKit using deterministic record ID
    /// - Parameter credits: The credit amount to save
    func saveCredits(_ credits: Int) async {
        guard isSignedIn else { return }

        let database = container.privateCloudDatabase
        let recordID = CKRecord.ID(recordName: creditsRecordName)

        do {
            let record: CKRecord

            do {
                // Try to fetch existing record by known ID
                record = try await database.record(for: recordID)
            } catch {
                // Record doesn't exist, create with this specific ID
                record = CKRecord(recordType: recordType, recordID: recordID)
            }

            record[creditsKey] = credits

            let savedRecord = try await database.save(record)
            creditsRecordID = savedRecord.recordID
            print("CloudKit: Credits saved successfully (\(credits))")
        } catch {
            print("CloudKit saveCredits error: \(error.localizedDescription)")
        }
    }

    /// Syncs credits from CloudKit - cloud is the source of truth
    /// - Parameter localCredits: The current local credit count (used only if no cloud record exists)
    /// - Returns: The cloud credit count (or local if no cloud record)
    func syncCredits(localCredits: Int) async -> Int {
        guard isSignedIn else { return localCredits }

        isSyncing = true
        defer { isSyncing = false }

        // Fetch credits from CloudKit - cloud is source of truth
        if let cloudCredits = await fetchCredits() {
            if cloudCredits != localCredits {
                print("CloudKit: Syncing local credits from \(localCredits) to \(cloudCredits)")
            }
            return cloudCredits
        } else {
            // No CloudKit record exists, create one with local credits
            await saveCredits(localCredits)
            print("CloudKit: Created new credits record with \(localCredits) credits")
            return localCredits
        }
    }

    // MARK: - Preferences Sync Methods

    /// Saves preferred categories to CloudKit
    /// - Parameter categories: Array of category raw values
    func savePreferredCategories(_ categories: [String]) async {
        guard isSignedIn else { return }

        let database = container.privateCloudDatabase
        let recordID = CKRecord.ID(recordName: preferencesRecordName)

        do {
            let record: CKRecord

            do {
                // Try to fetch existing record
                record = try await database.record(for: recordID)
            } catch {
                // Record doesn't exist, create new
                record = CKRecord(recordType: preferencesRecordType, recordID: recordID)
            }

            record[preferredCategoriesKey] = categories
            try await database.save(record)
            print("CloudKit: Preferred categories saved successfully")
        } catch {
            print("CloudKit savePreferredCategories error: \(error.localizedDescription)")
        }
    }

    /// Fetches preferred categories from CloudKit
    /// - Returns: Array of category raw values, or nil if no record exists
    func fetchPreferredCategories() async -> [String]? {
        guard isSignedIn else { return nil }

        let database = container.privateCloudDatabase
        let recordID = CKRecord.ID(recordName: preferencesRecordName)

        do {
            let record = try await database.record(for: recordID)
            return record[preferredCategoriesKey] as? [String]
        } catch {
            print("CloudKit fetchPreferredCategories: No record found")
            return nil
        }
    }
}
