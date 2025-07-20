//
//  View.swift
//  Ruby
//
//  Created by George Andrade-Munoz on 7/17/25.
//
import SwiftUI

extension View {
    func onPressGesture(perform action: @escaping (Bool) -> Void) -> some View {
        self.simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in action(true) }
                .onEnded { _ in action(false) }
        )
    }
    func blurredBackground() -> some View {
        modifier(BlurredBackgroundModifier())
    }
}
