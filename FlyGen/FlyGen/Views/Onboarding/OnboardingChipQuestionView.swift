import SwiftUI
import UIKit

/// The interactive language turn: the assistant asks, the user picks one language from a dropdown,
/// then Continue collapses the pick into a sent user bubble (handled by the view model). Single-select
/// (one design language per user); the review card lets them change it per flyer later.
struct OnboardingChipQuestionView: View {
    let question: OnboardingQuestion
    @ObservedObject var vm: ChatOnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: FGSpacing.sm) {
            AssistantBubble(text: question.prompt)

            LanguagePicker(selection: $vm.selectedLanguage)

            Button { vm.submitCurrentQuestion() } label: {
                Text("Continue")
                    .font(FGTypography.button)
                    .foregroundColor(FGColors.textOnAccent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, FGSpacing.sm)
                    .background(FGColors.accentPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: FGSpacing.buttonRadius))
            }
            .padding(.top, FGSpacing.xxs)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// The open, personal turn. The question itself ("what do you do?") is a preceding assistant beat;
/// this renders only the input field, a Send button, and a quiet Skip. On send or skip the view
/// model collapses this beat and resumes the script. Nothing typed here is stored - it's rapport.
struct OnboardingTextQuestionView: View {
    let placeholder: String
    @ObservedObject var vm: ChatOnboardingViewModel
    @FocusState private var focused: Bool

    private var canSend: Bool {
        !vm.textDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: FGSpacing.xs) {
            HStack(alignment: .center, spacing: FGSpacing.xs) {
                TextField(placeholder, text: $vm.textDraft)
                    .font(FGTypography.body)
                    .foregroundColor(FGColors.textPrimary)
                    .tint(FGColors.accentPrimary)
                    .focused($focused)
                    .submitLabel(.send)
                    .onSubmit(send)
                    .padding(.horizontal, FGSpacing.md)
                    .padding(.vertical, FGSpacing.sm)
                    .background(FGColors.surfaceDefault)
                    .clipShape(RoundedRectangle(cornerRadius: FGSpacing.buttonRadius))
                    .overlay(RoundedRectangle(cornerRadius: FGSpacing.buttonRadius)
                        .stroke(FGColors.borderSubtle, lineWidth: 1))

                Button(action: send) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(canSend ? FGColors.accentPrimary
                                                 : FGColors.textSecondary.opacity(0.35))
                }
                .disabled(!canSend)
                .animation(FGAnimations.spring, value: canSend)
            }

            Button { vm.submitTextQuestion(skipped: true) } label: {
                Text("Skip")
                    .font(FGTypography.caption)
                    .foregroundColor(FGColors.textSecondary)
                    .padding(.vertical, FGSpacing.xxs)
                    .padding(.horizontal, FGSpacing.xs)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear { focused = true }
    }

    private func send() {
        guard canSend else { return }
        vm.submitTextQuestion(skipped: false)
    }
}

// The chip wrap uses the shared `FlowLayout` (defined in Views/Result/RefinementSheet.swift),
// the same one the refinement and smart-extras chip rows use.

// MARK: - Small shared helpers

enum Haptics {
    static func selection() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

extension FlyerLanguage {
    /// Compact label for chips; the full `displayName` carries a parenthetical translation.
    var shortName: String {
        switch self {
        case .english: return "English"
        case .spanish: return "Español"
        case .urdu:    return "اردو"
        case .arabic:  return "العربية"
        case .chinese: return "中文"
        case .hindi:   return "हिन्दी"
        case .french:  return "Français"
        case .bengali: return "বাংলা"
        case .portuguese: return "Português"
        case .russian: return "Русский"
        case .indonesian: return "Indonesia"
        case .german:  return "Deutsch"
        case .japanese: return "日本語"
        }
    }
}
