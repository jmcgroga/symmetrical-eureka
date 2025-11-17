import SwiftUI
import VoiceJournalCore
import VoiceJournalStorage

/// Main macOS app view
public struct VoiceJournalmacOSApp: View {
    public init() {}

    public var body: some View {
        macOSJournalListView()
            .frame(minWidth: 800, minHeight: 600)
    }
}
