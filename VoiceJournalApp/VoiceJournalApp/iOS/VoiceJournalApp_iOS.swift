//
//  VoiceJournalApp_iOS.swift
//  VoiceJournalApp (iOS)
//
//  Created by Claude Code
//

import SwiftUI
import VoiceJournalStorage

@main
struct VoiceJournalApp_iOS: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(try! CloudKitSyncManager.shared.createModelContainer())
    }
}
