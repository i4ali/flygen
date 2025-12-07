import SwiftUI
import SwiftData

struct PremiumTab: View {
    @Query private var userProfiles: [UserProfile]

    private var credits: Int {
        userProfiles.first?.credits ?? 3
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Header illustration
                    VStack(spacing: 16) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.yellow, .orange],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        Text("FlyGen Premium")
                            .font(.title)
                            .fontWeight(.bold)

                        Text("Unlock unlimited flyer creation\nand premium features")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)

                    // Current credits
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundColor(.yellow)
                        Text("Current Credits: \(credits)")
                            .fontWeight(.medium)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.yellow.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)

                    // Features list
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Premium Features")
                            .font(.headline)
                            .padding(.horizontal)

                        FeatureRow(icon: "infinity", title: "Unlimited Flyers", description: "Create as many flyers as you need")
                        FeatureRow(icon: "wand.and.stars", title: "Advanced Styles", description: "Access exclusive design styles")
                        FeatureRow(icon: "clock.arrow.circlepath", title: "Priority Generation", description: "Faster image generation")
                        FeatureRow(icon: "icloud", title: "Cloud Backup", description: "Save your projects to the cloud")
                        FeatureRow(icon: "rectangle.stack", title: "Templates", description: "Start with professional templates")
                    }
                    .padding(.vertical)

                    // Coming Soon badge
                    VStack(spacing: 12) {
                        Text("Coming Soon")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        Text("Premium subscriptions will be available in a future update")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(16)
                    .padding(.horizontal)

                    Spacer(minLength: 40)
                }
            }
            .navigationTitle("Premium")
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        }
        .padding(.horizontal)
    }
}

#Preview {
    PremiumTab()
}
