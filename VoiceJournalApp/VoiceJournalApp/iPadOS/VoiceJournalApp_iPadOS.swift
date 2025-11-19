//
//  VoiceJournalApp_iPadOS.swift
//  VoiceJournalApp (iPadOS)
//
//  Created by Claude Code
//

import SwiftUI
import VoiceJournalStorage
import VoiceJournaliOS
import VoiceJournaliPadOS

@main
struct VoiceJournalApp_iPadOS: App {
    var body: some Scene {
        WindowGroup {
            // Use iPad-optimized view from VoiceJournaliPadOS package
            VoiceJournaliPadOSApp()
        }
        .modelContainer(try! CloudKitSyncManager.shared.createModelContainer())
    }
}
