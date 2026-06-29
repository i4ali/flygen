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
    private let quotaUsedKey = "quotaUsedThisPeriod"
    private let quotaPeriodStartKey = "quotaPeriodStart"

    /// Tail of the serialized write chain for the shared user-credits-record.
    /// Every write awaits the previous one so concurrent fetch-modify-save cycles
    /// can't clobber each other and trigger CloudKit "client oplock error".
    private var recordWriteTask: Task<Void, Never>?

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

    // MARK: - Serialized Record Writes

    /// Performs a fetch-modify-save on the shared user-credits-record, serialized
    /// against every other write so overlapping callers can't cause CloudKit oplock
    /// conflicts. Falls back to a fresh fetch + retry if the record changed
    /// underneath us (e.g. another device wrote concurrently).
    private func updateCreditsRecord(_ label: String, _ mutate: @escaping (CKRecord) -> Void) async {
        let previous = recordWriteTask
        let task = Task { [weak self] in
            await previous?.value
            await self?.performRecordUpdate(label, mutate)
        }
        recordWriteTask = task
        await task.value
    }

    private func performRecordUpdate(_ label: String, _ mutate: (CKRecord) -> Void, attempt: Int = 0) async {
        guard isSignedIn else { return }

        let database = container.privateCloudDatabase
        let recordID = CKRecord.ID(recordName: creditsRecordName)

        do {
            let record: CKRecord
            do {
                record = try await database.record(for: recordID)
            } catch {
                record = CKRecord(recordType: recordType, recordID: recordID)
            }

            mutate(record)

            let savedRecord = try await database.save(record)
            creditsRecordID = savedRecord.recordID
            print("CloudKit: \(label) saved successfully")
        } catch let error as CKError where error.code == .serverRecordChanged && attempt < 2 {
            // Record changed between fetch and save - re-fetch and retry with fresh state.
            await performRecordUpdate(label, mutate, attempt: attempt + 1)
        } catch {
            print("CloudKit save error (\(label)): \(error.localizedDescription)")
        }
    }

    // MARK: - Credit / Quota Writes

    /// Saves credits to CloudKit using the deterministic record ID.
    /// - Parameter credits: The credit amount to save
    func saveCredits(_ credits: Int) async {
        let key = creditsKey
        await updateCreditsRecord("Credits (\(credits))") { record in
            record[key] = credits
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

    // MARK: - Quota Sync Methods

    /// Fetches quota fields from CloudKit using the same user-credits-record.
    /// - Returns: A tuple (quotaUsed, periodStart), or nil if no record exists.
    func fetchQuota() async -> (used: Int, periodStart: Date?)? {
        guard isSignedIn else { return nil }

        let database = container.privateCloudDatabase
        let recordID = CKRecord.ID(recordName: creditsRecordName)

        do {
            let record = try await database.record(for: recordID)
            let used = record[quotaUsedKey] as? Int ?? 0
            let periodStart = record[quotaPeriodStartKey] as? Date
            return (used, periodStart)
        } catch {
            print("CloudKit fetchQuota: No record found")
            return nil
        }
    }

    /// Saves quota fields to CloudKit using the same user-credits-record.
    func saveQuota(used: Int, periodStart: Date?) async {
        let usedKey = quotaUsedKey
        let startKey = quotaPeriodStartKey
        await updateCreditsRecord("Quota (used=\(used), periodStart=\(String(describing: periodStart)))") { record in
            record[usedKey] = used
            record[startKey] = periodStart as CKRecordValue?
        }
    }

    /// Saves credits and quota together in a single record write, so the two
    /// values that change on every generation never race each other.
    func saveCreditsAndQuota(credits: Int, quotaUsed: Int, periodStart: Date?) async {
        let cKey = creditsKey
        let usedKey = quotaUsedKey
        let startKey = quotaPeriodStartKey
        await updateCreditsRecord("Credits+Quota (credits=\(credits), used=\(quotaUsed))") { record in
            record[cKey] = credits
            record[usedKey] = quotaUsed
            record[startKey] = periodStart as CKRecordValue?
        }
    }

    /// Syncs quota from CloudKit - cloud is the source of truth.
    /// - Parameters:
    ///   - localUsed: Current local quota-used count (used only if no cloud record exists).
    ///   - localPeriodStart: Current local period start (used only if no cloud record exists).
    /// - Returns: The cloud quota values (or local if no cloud record exists yet).
    func syncQuota(localUsed: Int, localPeriodStart: Date?) async -> (used: Int, periodStart: Date?) {
        guard isSignedIn else { return (localUsed, localPeriodStart) }

        if let cloud = await fetchQuota() {
            if cloud.used != localUsed || cloud.periodStart != localPeriodStart {
                print("CloudKit: Syncing local quota from (\(localUsed), \(String(describing: localPeriodStart))) to (\(cloud.used), \(String(describing: cloud.periodStart)))")
            }
            return cloud
        } else {
            // No CloudKit record exists yet; seed it from local values.
            await saveQuota(used: localUsed, periodStart: localPeriodStart)
            print("CloudKit: Created new quota record with used=\(localUsed)")
            return (localUsed, localPeriodStart)
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
