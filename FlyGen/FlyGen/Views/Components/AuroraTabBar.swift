import SwiftUI
import UIKit

/// Aurora custom tab bar. Rendered over a `TabView` whose native bar is hidden
/// (`.toolbar(.hidden, for: .tabBar)`) and inset via `.safeAreaInset(edge: .bottom)`, so the
/// TabView keeps its state preservation / lazy loading while the bar is fully custom:
/// flat near-black, hairline top, indigo active icon+label, tertiary inactive.
struct AuroraTabBar: View {
    @Binding var selection: Int

    private struct Item { let title: String; let icon: String; let tag: Int }
    private let items: [Item] = [
        Item(title: "Home",      icon: "house",           tag: 0),
        Item(title: "My Flyers", icon: "square.grid.2x2", tag: 1),
        Item(title: "Explore",   icon: "sparkles",        tag: 2),
        Item(title: "Prompts",   icon: "text.bubble",     tag: 3),
        Item(title: "Profile",   icon: "person",          tag: 4)
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items, id: \.tag) { item in
                let isActive = selection == item.tag
                Button {
                    if selection != item.tag {
                        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    }
                    selection = item.tag
                } label: {
                    VStack(spacing: 5) {
                        Image(systemName: item.icon)
                            .font(.system(size: 22, weight: isActive ? .medium : .regular))
                        Text(item.title)
                            .font(isActive ? FGTypography.tabLabel : FGTypography.tabLabelInactive)
                    }
                    .foregroundColor(isActive ? FGColors.accentPrimary : FGColors.textTertiary)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 12)
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity)
        .background {
            // Near-black bar with a hairline top edge; the fill bleeds under the home indicator
            // while the touch targets stay above the safe area.
            FGColors.backgroundPrimary
                .overlay(alignment: .top) {
                    Rectangle().fill(FGColors.borderHairline).frame(height: 1)
                }
                .ignoresSafeArea(edges: .bottom)
        }
        // Keep the bar pinned to the bottom rather than riding up with the keyboard.
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .animation(FGAnimations.ease, value: selection)
    }
}

#Preview {
    struct Wrap: View {
        @State var sel = 0
        var body: some View {
            ZStack { FGColors.backgroundPrimary.ignoresSafeArea() }
                .safeAreaInset(edge: .bottom, spacing: 0) { AuroraTabBar(selection: $sel) }
        }
    }
    return Wrap()
}
