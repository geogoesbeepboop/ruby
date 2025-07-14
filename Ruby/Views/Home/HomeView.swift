import SwiftUI

@available(iOS 26.0, *)
struct HomeView: View {
    @State private var pulseAnimation = false
    
    var body: some View {
        ZStack {
                // Base animated background
                MaterialBackground()
                    .ignoresSafeArea()
                
                // Floating orbs for ambient animation
                FloatingOrb(
                    size: 60,
                    color: Color(hex: "fc9afb").opacity(0.3),
                    offset: CGSize(width: -100, height: -200),
                    delay: 0
                )
                
                FloatingOrb(
                    size: 40,
                    color: Color(hex: "9b6cb0").opacity(0.4),
                    offset: CGSize(width: 120, height: 150),
                    delay: 1.5
                )
                
                FloatingOrb(
                    size: 80,
                    color: Color(hex: "f7e6ff").opacity(0.2),
                    offset: CGSize(width: -80, height: 300),
                    delay: 3.0
                )
                
                // Main content
                VStack(spacing: 40) {
                    Spacer()
                    
                    // Welcome content container
                    GlassEffectContainer(
                        cornerRadius: 24,
                        blurRadius: 12,
                        opacity: 0.3
                    ) {
                        VStack(spacing: 24) {
                            // App icon or logo area
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(hex: "fc9afb").opacity(0.8),
                                            Color(hex: "9b6cb0").opacity(0.6)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 80, height: 80)
                                .overlay {
                                    Image(systemName: "heart.fill")
                                        .font(.system(size: 36, weight: .medium))
                                        .foregroundStyle(.white)
                                }
                                .scaleEffect(pulseAnimation ? 1.05 : 1.0)
                                .animation(
                                    .easeInOut(duration: 2)
                                    .repeatForever(autoreverses: true),
                                    value: pulseAnimation
                                )
                            
                            // Main welcome text
                            VStack(spacing: 8) {
                                Text("Lotus AI")
                                    .font(.system(size: 32, weight: .medium, design: .rounded))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Color(hex: "fc9afb"), Color(hex: "9b6cb0")],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                
                                Text("What should we do now?")
                                    .font(.system(size: 20, weight: .medium, design: .rounded))
                                    .foregroundStyle(.primary.opacity(0.8))
                                    .multilineTextAlignment(.center)
                            }
                            
                            // Subtitle
                            Text("Your intelligent companion is ready to help with any conversation, question, or creative task.")
                                .font(.system(size: 16, weight: .regular, design: .rounded))
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .lineLimit(3)
                        }
                        .padding(.horizontal, 32)
                        .padding(.vertical, 40)
                    }
                    .padding(.horizontal, 24)
                    
                    // Action buttons
                    VStack(spacing: 16) {
                        // Primary chat button
                        PulsingButton(isActive: true) {
                            switchToChatTab()
                        } content: {
                            GlassEffectContainer(
                                cornerRadius: 25,
                                blurRadius: 10,
                                opacity: 0.4
                            ) {
                                HStack(spacing: 12) {
                                    Image(systemName: "message.circle.fill")
                                        .font(.system(size: 20, weight: .medium))
                                    
                                    Text("Start Conversation")
                                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                                }
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color(hex: "fc9afb"), Color(hex: "9b6cb0")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(maxWidth: 280, minHeight: 50)
                            }
                        }
                        
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer()
                }
                
                // Sparkle effects overlaid on top of all content
                SparkleEffect()
            }
            .onAppear {
                pulseAnimation = true
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Ruby AI Home Screen")
        }
    
    private func switchToChatTab() {
        // This will be handled by the TabView selection in MainContainerView
        // For now, we'll use a notification approach or pass a binding
        NotificationCenter.default.post(name: .switchToChatTab, object: nil)
    }
}


// MARK: - Notification Extension

extension Notification.Name {
    static let switchToChatTab = Notification.Name("switchToChatTab")
}

// MARK: - Preview

@available(iOS 26.0, *)
#Preview {
    HomeView()
}
