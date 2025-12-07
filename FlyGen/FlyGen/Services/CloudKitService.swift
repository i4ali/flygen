import CloudKit
import SwiftUI

@MainActor
class CloudKitService: ObservableObject {
    @Published var accountStatus: CKAccountStatus = .couldNotDetermine
    @Published var userRecordID: CKRecord.ID?
    @Published var isSignedIn: Bool = false
    @Published var isChecking: Bool = true

    private let container = CKContainer(identifier: "iCloud.com.flygen.app")

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
}
