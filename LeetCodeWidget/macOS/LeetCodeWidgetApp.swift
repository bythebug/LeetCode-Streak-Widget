//
//  LeetCodeWidgetApp.swift
//  LeetCodeWidget macOS
//
//  Created by Suraj Van Verma
//

import SwiftUI

@main
struct LeetCodeWidgetApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.automatic)
        .defaultSize(width: 900, height: 800)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}

