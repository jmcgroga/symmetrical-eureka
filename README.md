# VoiceJournal

A modular, cross-platform daily journaling application for iOS, iPadOS, and macOS with voice input, Apple Pencil support, AI-powered weekly summaries, and iCloud sync.

## Features

- **Cross-Platform**: Native apps for iOS, iPadOS, and macOS
- **iCloud Sync**: All journal entries synchronized across devices via iCloud
- **Voice Journaling**: Hold-to-record button with speech-to-text on all platforms
- **Multi-Input Support**:
  - Keyboard text entry (all platforms)
  - Apple Pencil with Scribble (iPadOS)
  - Drawing canvas (iPadOS)
- **Smart Notifications**:
  - Daily reminders to journal (configurable time)
  - Weekly summary notifications (configurable day and time)
- **AI-Powered Summaries**: Weekly journal summaries using Apple Intelligence (iOS 18+/macOS 15+)
- **Platform Metadata**: Track which device and platform each entry was created on

## Architecture

VoiceJournal is built as a modular multi-package system:

```
VoiceJournal/
├── VoiceJournalCore/        # Shared models, protocols
├── VoiceJournalStorage/     # iCloud sync via SwiftData + CloudKit
├── VoiceJournaliOS/         # iOS-specific implementation
├── VoiceJournaliPadOS/      # iPadOS-specific features
└── VoiceJournalmacOS/       # macOS-specific implementation
```

### Package Overview

**VoiceJournalCore**
- Platform-agnostic models (`JournalEntry`, `AppSettings`)
- Protocols for services (`VoiceInputProtocol`, `NotificationServiceProtocol`, etc.)
- Shared business logic
- Platforms: iOS 18+, macOS 15+

**VoiceJournalStorage**
- iCloud synchronization using SwiftData + CloudKit
- `CloudKitSyncManager` for automatic cross-device sync
- `SummaryService` for AI-powered weekly summaries
- Platforms: iOS 18+, macOS 15+

**VoiceJournaliOS**
- iOS-specific UI and services
- Voice recording with Speech framework
- User notifications
- Standard iPhone interface
- Platform: iOS 18+

**VoiceJournaliPadOS**
- Extends iOS functionality for iPad
- Enhanced Apple Pencil support with PencilKit
- Scribble handwriting-to-text
- Drawing canvas for sketches
- Platform: iOS 18+ (iPadOS)

**VoiceJournalmacOS**
- Native macOS interface with split view
- Keyboard shortcuts
- Menu bar integration
- macOS-specific voice recording
- Platform: macOS 15+

## Requirements

- **iOS/iPadOS**: iOS 18.0+ / iPadOS 18.0+
- **macOS**: macOS 15.0+
- **Xcode**: 16.0+
- **Swift**: 6.2+
- **iCloud**: iCloud account with CloudKit enabled

## Installation

### For iOS/iPadOS App

1. Create a new iOS App project in Xcode
2. Add package dependencies as local packages:
   - Add `VoiceJournaliOS` package
   - Add `VoiceJournaliPadOS` package (if supporting iPad)
   - Add `VoiceJournalStorage` package
3. Import the appropriate modules:

```swift
import SwiftUI
import VoiceJournaliOS
import VoiceJournaliPadOS
import VoiceJournalStorage

@main
struct MyJournalApp: App {
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

4. Add required Info.plist permissions:

```xml
<key>NSSpeechRecognitionUsageDescription</key>
<string>We need access to speech recognition to transcribe your voice journal entries.</string>

<key>NSMicrophoneUsageDescription</key>
<string>We need access to the microphone to record your voice journal entries.</string>
```

5. Enable iCloud capability:
   - Go to Signing & Capabilities
   - Add "iCloud" capability
   - Check "CloudKit"
   - Select or create a CloudKit container

### For macOS App

1. Create a new macOS App project in Xcode
2. Add package dependencies as local packages:
   - Add `VoiceJournalmacOS` package
   - Add `VoiceJournalStorage` package
3. Import the macOS modules:

```swift
import SwiftUI
import VoiceJournalmacOS
import VoiceJournalStorage

@main
struct MyJournalMacApp: App {
    var body: some Scene {
        WindowGroup {
            VoiceJournalmacOSApp()
        }
        .modelContainer(try! CloudKitSyncManager.shared.createModelContainer())
        .commands {
            // Add custom menu commands
        }
    }
}
```

4. Add required Info.plist permissions (same as iOS)
5. Enable iCloud capability with CloudKit

## iCloud Sync Setup

### CloudKit Container Configuration

1. In your Xcode project, go to Signing & Capabilities
2. Add iCloud capability
3. Enable CloudKit
4. Create or select a CloudKit container (e.g., `iCloud.com.yourcompany.voicejournal`)
5. SwiftData will automatically sync using this container

### Important Notes

- The same CloudKit container identifier must be used across iOS, iPadOS, and macOS apps
- All devices must be signed into the same iCloud account
- Sync happens automatically in the background
- Conflicts are resolved using SwiftData's automatic conflict resolution
- Settings are synced via NSUbiquitousKeyValueStore

## Development

### Building Individual Packages

Each package can be built independently:

```bash
# Build Core package
cd VoiceJournalCore
swift build

# Build Storage package
cd VoiceJournalStorage
swift build

# Build iOS package
cd VoiceJournaliOS
swift build

# Build macOS package
cd VoiceJournalmacOS
swift build
```

### Testing

- iOS/iPadOS features require physical devices for full testing
- Voice features don't work well in simulator
- iCloud sync requires actual iCloud accounts
- Apple Pencil features require iPad with Apple Pencil

## Platform-Specific Features

### iOS
- Standard iPhone interface
- Portrait and landscape support
- Voice recording with hold-to-record button
- Daily and weekly notifications

### iPadOS
- All iOS features plus:
- Apple Pencil support with Scribble
- PencilKit drawing canvas
- Enhanced text editing with handwriting
- Optimized for larger screen

### macOS
- Native macOS interface with split view
- Keyboard shortcuts (⌘S to save, ⌘N for new entry)
- Menu bar integration
- Window management
- Search functionality in sidebar

## Documentation

- [CLAUDE.md](CLAUDE.md) - Architecture and development guide
- [INTEGRATION.md](INTEGRATION.md) - Platform-specific integration instructions
- Individual package documentation in each package directory

## License

(Add your license here)

## Support

For detailed integration instructions, see [INTEGRATION.md](INTEGRATION.md).

For codebase architecture and development guidance, see [CLAUDE.md](CLAUDE.md).
