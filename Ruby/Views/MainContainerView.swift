import SwiftUI

@available(iOS 26.0, *)
struct MainContainerView: View {
    @State private var selectedTab: Tab = .home
    @State private var showingChat = false
    
    enum Tab: String, CaseIterable {
        case home = "Home"
        case chat = "Chat"
        case actions = "Actions"
        
        var systemImage: String {
            switch self {
            case .home:
                return "house.fill"
            case .chat:
                return "message.fill"
            case .actions:
                return "slider.horizontal.3"
            }
        }
        
        var inactiveSystemImage: String {
            switch self {
            case .home:
                return "house"
            case .chat:
                return "message"
            case .actions:
                return "slider.horizontal.3"
            }
        }
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab
            HomeView()
                .tabItem {
                    Image(systemName: selectedTab == .home ? Tab.home.systemImage : Tab.home.inactiveSystemImage)
                    Text(Tab.home.rawValue)
                }
                .tag(Tab.home)
            
            // Chat Tab
            NavigationStack {
                MainChatBotView()
                    .navigationBarBackButtonHidden(true)
            }
            .tabItem {
                Image(systemName: selectedTab == .chat ? Tab.chat.systemImage : Tab.chat.inactiveSystemImage)
                Text(Tab.chat.rawValue)
            }
            .tag(Tab.chat)
            
            // Actions Tab
            ActionsView()
                .tabItem {
                    Image(systemName: selectedTab == .actions ? Tab.actions.systemImage : Tab.actions.inactiveSystemImage)
                    Text(Tab.actions.rawValue)
                }
                .tag(Tab.actions)
        }
        .tint(Color.brandPrimary)
        .onAppear {
            // Customize tab bar appearance with glass effect
            setupTabBarAppearance()
        }
        .onReceive(NotificationCenter.default.publisher(for: .switchToChatTab)) { _ in
            selectedTab = .chat
        }
    }
    
    private func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        
        // Add blur effect to tab bar
        appearance.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.1)
        
        // Customize tab item colors
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.systemGray
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.systemGray
        ]
        
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color.brandPrimary)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(Color.brandPrimary)
        ]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

// MARK: - Preview

@available(iOS 26.0, *)
#Preview {
    MainContainerView()
}
