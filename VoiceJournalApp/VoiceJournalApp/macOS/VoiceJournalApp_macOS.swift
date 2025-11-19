//
//  VoiceJournalApp_macOS.swift
//  VoiceJournalApp (macOS)
//
//  Created by Claude Code
//

import SwiftUI
import VoiceJournalStorage
import VoiceJournalmacOS

@main
struct VoiceJournalApp_macOS: App {
    var body: some Scene {
        WindowGroup {
            VoiceJournalmacOSApp()
        }
        .modelContainer(try! CloudKitSyncManager.shared.createModelContainer())
    }
}
