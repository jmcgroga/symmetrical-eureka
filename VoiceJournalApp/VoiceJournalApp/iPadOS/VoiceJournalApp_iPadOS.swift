//
//  VoiceJournalApp_iPadOS.swift
//  VoiceJournalApp (iPadOS)
//
//  Created by Claude Code
//

import SwiftUI
import VoiceJournalStorage

@main
struct VoiceJournalApp_iPadOS: App {
    var body: some Scene {
        WindowGroup {
            ContentView_iPadOS()
        }
        .modelContainer(try! CloudKitSyncManager.shared.createModelContainer())
    }
}
