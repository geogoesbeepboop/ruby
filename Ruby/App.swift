//
//  RubyApp.swift
//  Ruby
//
//  Created by George Andrade-Munoz on 7/11/25.
//

import SwiftUI
import SwiftData

@main
struct RubyApp: App {
    let dataManager = DataManager.shared

    var body: some Scene {
        WindowGroup {
            MainContainerView()
                .modelContainer(dataManager.container)
        }
    }
}
