import SwiftUI

// MARK: - Lotus Color Theme
extension Color {    
    // MARK: - Semantic Color Mapping
    /// Primary brand color - replaces #fc9afb
    static let brandPrimary = lotusPrimary
    
    /// Secondary brand color - replaces #b016f7  
    static let brandSecondary = lotusDark
    
    /// Highlight/accent color - replaces #f7e6ff
    static let brandHighlight = lotusHighlight
    
    /// Accent color for interactive elements
    static let brandAccent = lotusAccent
    
    /// App background color
    static let appBackground = lotusBackground
    
    /// Secondary text color
    static let textSecondary = lotusSecondary
    
    // MARK: - Gradient Combinations
    /// Primary gradient for buttons and highlights
    static let brandGradient = LinearGradient(
        colors: [brandPrimary, brandSecondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// Subtle highlight gradient
    static let highlightGradient = LinearGradient(
        colors: [brandHighlight, brandAccent],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - Deprecated Colors (for migration reference)
extension Color {
    @available(*, deprecated, message: "Use Color.brandPrimary instead")
    static let rubyPrimary = Color("RubyPrimary")
    
    @available(*, deprecated, message: "Use Color.brandSecondary instead")
    static let rubyDark = Color("RubyDark")
    
    @available(*, deprecated, message: "Use Color.textSecondary instead")
    static let rubySecondary = Color("RubySecondary")
    
    @available(*, deprecated, message: "Use Color.brandAccent instead")
    static let rubyAccent = Color("RubyAccent")
    
    @available(*, deprecated, message: "Use Color.appBackground instead")
    static let rubyBackground = Color("RubyBackground")
    
    @available(*, deprecated, message: "Use Color.brandHighlight instead")
    static let rubyHighlight = Color("RubyHighlight")
}
