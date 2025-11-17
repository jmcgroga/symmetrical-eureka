# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

VoiceJournal is a modular, cross-platform daily journaling system built with Swift and SwiftUI. The codebase is organized as multiple Swift Packages to enable code sharing across iOS, iPadOS, and macOS while maintaining platform-specific implementations.

**Platform Support:**
- iOS 18.0+
- iPadOS 18.0+
- macOS 15.0+
- Swift 6.2+
- Xcode 16.0+

## Core Features

1. **Cross-Platform Journaling**: Native apps for iOS, iPadOS, and macOS
2. **iCloud Sync**: Automatic synchronization using SwiftData + CloudKit
3. **Voice Input**: Speech-to-text on all platforms
4. **Multi-Input**: Keyboard, Apple Pencil (iPad), Drawing canvas (iPad)
5. **Smart Notifications**: Configurable daily and weekly reminders
6. **AI Summaries**: Weekly summaries via Apple Intelligence
7. **Platform Metadata**: Track which device created each entry

## Architecture

### Multi-Package Structure

```
VoiceJournal/
├── VoiceJournalCore/        # Shared models and protocols
├── VoiceJournalStorage/     # iCloud sync layer
├── VoiceJournaliOS/         # iOS implementation
├── VoiceJournaliPadOS/      # iPadOS enhancements
└── VoiceJournalmacOS/       # macOS implementation
```

Each directory is an independent Swift Package with its own `Package.swift`.

### Package Details

#### VoiceJournalCore (VoiceJournalCore/)
**Purpose**: Platform-agnostic core functionality
**Platforms**: iOS 18+, macOS 15+

**Contents**:
- `Models/`
  - `JournalEntry.swift` - SwiftData model with platform tracking
  - `AppSettings.swift` - User preferences with iCloud sync
- `Protocols/`
  - `VoiceInputProtocol.swift` - Voice recording interface
  - `NotificationServiceProtocol.swift` - Notification interface
  - `SummaryServiceProtocol.swift` - Summary generation interface

**Key Points**:
- All models are `public` for cross-package access
- `JournalEntry` includes `platform` field (iOS/iPadOS/macOS) and `deviceName`
- `AppSettings` syncs via `NSUbiquitousKeyValueStore` for iCloud
- Protocols define contracts for platform-specific implementations

#### VoiceJournalStorage (VoiceJournalStorage/)
**Purpose**: iCloud sync and data persistence
**Platforms**: iOS 18+, macOS 15+
**Dependencies**: VoiceJournalCore

**Contents**:
- `CloudKitSyncManager.swift` - SwiftData + CloudKit configuration
- `SummaryService.swift` - Shared summary generation logic

**Key Points**:
- `createModelContainer()` enables CloudKit sync via `cloudKitDatabase: .automatic`
- SwiftData handles conflict resolution automatically
- Summary service works across all platforms
- Settings sync separately via NSUbiquitousKeyValueStore

#### VoiceJournaliOS (VoiceJournaliOS/)
**Purpose**: iOS-specific UI and services
**Platform**: iOS 18+
**Dependencies**: VoiceJournalCore, VoiceJournalStorage

**Contents**:
- `Services/`
  - `VoiceRecordingService.swift` - Speech recognition implementation
  - `NotificationService.swift` - UNUserNotificationCenter wrapper
- `Views/`
  - `JournalListView.swift` - Main timeline
  - `JournalEntryView.swift` - Create entry with voice
  - `EntryDetailView.swift` - View/edit entry
  - `WeeklySummaryView.swift` - Display summary
  - `SettingsView.swift` - Configure notifications and iCloud
- `VoiceJournaliOSApp.swift` - Root view

**Key Points**:
- Uses AVFoundation + Speech for voice recording
- Hold-to-record gesture via DragGesture
- UIDevice detection for platform metadata
- Standard iOS navigation patterns

#### VoiceJournaliPadOS (VoiceJournaliPadOS/)
**Purpose**: iPad-specific enhancements
**Platform**: iOS 18+ (iPadOS)
**Dependencies**: VoiceJournalCore, VoiceJournalStorage, VoiceJournaliOS

**Contents**:
- `Views/`
  - `iPadJournalEntryView.swift` - Enhanced entry with drawing
- `VoiceJournaliPadOSApp.swift` - Root view

**Key Points**:
- Extends iOS functionality (imports VoiceJournaliOS)
- PencilKit integration for drawing canvas
- Scribble automatically enabled on TextEditor
- Side-by-side text and drawing interface

#### VoiceJournalmacOS (VoiceJournalmacOS/)
**Purpose**: Native macOS application
**Platform**: macOS 15+
**Dependencies**: VoiceJournalCore, VoiceJournalStorage

**Contents**:
- `Services/`
  - `macOSVoiceRecordingService.swift` - macOS voice input
  - `macOSNotificationService.swift` - macOS notifications
- `Views/`
  - `macOSJournalListView.swift` - Split view interface
  - `macOSJournalEntryView.swift` - Entry creation
  - `macOSEntryDetailView.swift` - Detail view
  - `macOSWeeklySummaryView.swift` - Summary
  - `macOSSettingsView.swift` - Settings
- `VoiceJournalmacOSApp.swift` - Root view

**Key Points**:
- NavigationSplitView for sidebar + detail
- Keyboard shortcuts (⌘S, ⌘N, ⌘W, Esc)
- Search functionality in sidebar
- macOS-specific UI patterns (sheets with explicit sizes)
- Host.current().localizedName for device name

## Build Commands

**Build specific package:**
```bash
cd VoiceJournalCore
swift build
```

**Open package in Xcode:**
```bash
cd VoiceJournalCore
open Package.swift
```

Note: Each package must be built from its own directory.

## iCloud Sync Implementation

### SwiftData + CloudKit
- Configured via `ModelConfiguration(cloudKitDatabase: .automatic)`
- Sync happens automatically in background
- No manual sync code required
- Conflict resolution handled by SwiftData

### Settings Sync
- Uses `NSUbiquitousKeyValueStore` for settings
- Settings saved to both UserDefaults (local) and iCloud
- Automatic sync across devices
- Fallback to local if iCloud unavailable

### Platform Tracking
- Each `JournalEntry` records:
  - `platform`: iOS, iPadOS, or macOS
  - `deviceName`: User-friendly device name
  - Helps users see where entries were created

## Common Development Tasks

### Adding a New Field to JournalEntry

1. Update model in `VoiceJournalCore/Sources/VoiceJournalCore/Models/JournalEntry.swift`
2. Update UI in all three platforms:
   - iOS: `VoiceJournaliOS/Sources/VoiceJournaliOS/Views/`
   - iPadOS: `VoiceJournaliPadOS/Sources/VoiceJournaliPadOS/Views/`
   - macOS: `VoiceJournalmacOS/Sources/VoiceJournalmacOS/Views/`
3. SwiftData handles migration automatically

### Creating a New Platform-Specific Feature

1. Define protocol in `VoiceJournalCore/Protocols/` if shared
2. Implement in platform-specific package
3. Update views to use new feature
4. Test on all platforms where applicable

### Modifying iCloud Sync Behavior

1. Edit `CloudKitSyncManager.swift` in VoiceJournalStorage package
2. Modify `ModelConfiguration` settings
3. Changes apply to all platforms automatically

### Adding Platform-Specific UI

**iOS/iPadOS:**
- Add view to `VoiceJournaliOS/Sources/VoiceJournaliOS/Views/`
- Use iOS-specific APIs (UIKit interop if needed)

**macOS:**
- Add view to `VoiceJournalmacOS/Sources/VoiceJournalmacOS/Views/`
- Use AppKit interop where needed
- Follow macOS HIG (Human Interface Guidelines)

### Testing Across Platforms

1. Create iOS app project, import `VoiceJournaliOS`
2. Create macOS app project, import `VoiceJournalmacOS`
3. Use same CloudKit container ID in both
4. Sign in with same iCloud account
5. Test sync between devices

## Integration Notes

### For iOS/iPadOS Apps

```swift
import VoiceJournaliOS
import VoiceJournaliPadOS
import VoiceJournalStorage

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            #if os(iOS)
            if UIDevice.current.userInterfaceIdiom == .pad {
                VoiceJournaliPadOSApp()
            } else {
                VoiceJournaliOSApp()
            }
            #endif
        }
        .modelContainer(try! CloudKitSyncManager.shared.createModelContainer())
    }
}
```

### For macOS Apps

```swift
import VoiceJournalmacOS
import VoiceJournalStorage

@main
struct MyMacApp: App {
    var body: some Scene {
        WindowGroup {
            VoiceJournalmacOSApp()
        }
        .modelContainer(try! CloudKitSyncManager.shared.createModelContainer())
    }
}
```

### Required Capabilities

**All Platforms:**
- iCloud → CloudKit (with same container ID)
- App Sandbox → Network (for CloudKit)
- Background Modes → Remote notifications (optional)

**Info.plist Keys:**
```xml
<key>NSSpeechRecognitionUsageDescription</key>
<string>...</string>
<key>NSMicrophoneUsageDescription</key>
<string>...</string>
```

## Package Dependencies

```
VoiceJournalCore (no dependencies)
    ↑
    ├── VoiceJournalStorage
    │       ↑
    │       ├── VoiceJournaliOS
    │       │       ↑
    │       │       └── VoiceJournaliPadOS
    │       │
    │       └── VoiceJournalmacOS
```

## Best Practices

1. **Keep Core package platform-agnostic**: No UIKit/AppKit imports in Core
2. **Use protocols for platform-specific features**: Define in Core, implement in platform packages
3. **Public access for shared code**: Mark types/functions `public` when needed across packages
4. **Test on real devices**: iCloud sync requires actual devices and accounts
5. **Same CloudKit container**: Use identical container ID across all platforms
6. **Handle offline gracefully**: SwiftData queues changes until connection available
7. **Platform detection**: Use `#if os(iOS)` / `#if os(macOS)` for platform-specific code
