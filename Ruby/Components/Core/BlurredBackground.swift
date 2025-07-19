//
//  BlurredBackground.swift
//  Ruby
//
//  Created by George Andrade-Munoz on 7/18/25.
//
import SwiftUI

struct BlurredBackgroundModifier: ViewModifier {
//    @Environment(\.colorScheme) var colorScheme
    func body(content: Content) -> some View {
        content
//            .padding(.top, 16)
            .background {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .mask {
                        LinearGradient(colors: [.clear, .white, .white], startPoint: .top, endPoint: .bottom)
                    }
                    .overlay {
                        LinearGradient(colors: [
                            overlayColor.opacity(0),
                            overlayColor.opacity(0.6)
                        ], startPoint: .top, endPoint: .bottom)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea() 
            }
    }
    
    var overlayColor: Color {
        return Color(uiColor: .systemBackground)
    }
}
