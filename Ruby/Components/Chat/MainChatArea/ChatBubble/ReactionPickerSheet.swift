//
//  ReactionPickerSheet.swift
//  Ruby
//
//  Created by George Andrade-Munoz on 7/14/25.
//
import SwiftUI

@available(iOS 26.0, *)
struct ReactionPickerSheet: View {
    @Environment(ChatCoordinator.self) private var chatCoordinator
    @Environment(\.dismiss) private var dismiss
    let messageId: UUID?

    private let reactions = ["👍", "❤️", "😂", "😮", "😢", "😡", "🤔", "👏"]

    var body: some View {
        VStack(spacing: 20) {
            Text("Add Reaction")
                .font(.headline)
                .foregroundStyle(.primary)

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible()), count: 4),
                spacing: 16
            ) {
                ForEach(reactions, id: \.self) { reaction in
                    Button(action: {
                        if let messageId = messageId {
                            Task {
                                await chatCoordinator.addReaction(
                                    to: messageId,
                                    reaction: reaction
                                )
                            }
                        }
                        dismiss()
                    }) {
                        Text(reaction)
                            .font(.largeTitle)
                            .frame(width: 60, height: 60)
                            .background(
                                .ultraThinMaterial,
                                in: RoundedRectangle(cornerRadius: 16)
                            )
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 20)
    }
}
