//
//  VoiceJournalApp_iOS.swift
//  VoiceJournalApp (iOS)
//
//  Created by Claude Code
//

import SwiftUI
import VoiceJournalStorage
import VoiceJournaliOS

@main
struct VoiceJournalApp_iOS: App {
    var body: some Scene {
        WindowGroup {
            JournalListView()
        }
        .modelContainer(try! CloudKitSyncManager.shared.createModelContainer())
    }
}
