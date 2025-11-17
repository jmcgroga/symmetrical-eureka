import SwiftUI
import VoiceJournalCore
import VoiceJournalStorage
import VoiceJournaliOS

/// Main iPadOS app view with iPad-optimized layout
public struct VoiceJournaliPadOSApp: View {
    public init() {}

    public var body: some View {
        // Use the standard iOS list view but could be customized for iPad
        // with split view, sidebar, etc.
        JournalListView()
    }
}
