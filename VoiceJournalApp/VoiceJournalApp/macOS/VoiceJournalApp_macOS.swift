//
//  VoiceJournalApp_macOS.swift
//  VoiceJournalApp (macOS)
//
//  Created by Claude Code
//

import SwiftUI
import VoiceJournalStorage

@main
struct VoiceJournalApp_macOS: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(try! CloudKitSyncManager.shared.createModelContainer())
    }
}
