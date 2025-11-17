# VoiceJournal Integration Guide

This guide explains how to integrate VoiceJournal packages into your iOS, iPadOS, or macOS applications.

## Quick Start

VoiceJournal is organized as multiple independent Swift Packages in separate directories:
- **VoiceJournalCore**: Shared models and protocols
- **VoiceJournalStorage**: iCloud sync via SwiftData + CloudKit
- **VoiceJournaliOS**: iOS-specific implementation
- **VoiceJournaliPadOS**: iPadOS enhancements (Apple Pencil, drawing)
- **VoiceJournalmacOS**: macOS-specific implementation

Each package directory contains its own `Package.swift` and can be added independently to your Xcode project.

## iOS/iPadOS Integration

### Step 1: Create Xcode Project

1. Open Xcode
2. Create new project: **File → New → Project**
3. Select **iOS → App**
4. Choose:
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Storage: None (we'll use our own)

### Step 2: Add Package Dependencies

1. Select your project in Project Navigator
2. Select your app target
3. Go to **General → Frameworks, Libraries, and Embedded Content**
4. For each package you need, click **+** → **Add Package Dependency** → **Add Local...**
5. Add these packages individually:
   - Navigate to `VoiceJournal/VoiceJournaliOS` and add it
   - Navigate to `VoiceJournal/VoiceJournaliPadOS` and add it (if supporting iPad)
   - Navigate to `VoiceJournal/VoiceJournalStorage` and add it

Note: The dependency packages (Core, Storage) will be added automatically.

### Step 3: Update Your App File

Replace the contents of your app file (e.g., `MyJournalApp.swift`):

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

### Step 4: Add Info.plist Permissions

Add these keys to your `Info.plist`:

```xml
<key>NSSpeechRecognitionUsageDescription</key>
<string>We need access to speech recognition to transcribe your voice journal entries.</string>

<key>NSMicrophoneUsageDescription</key>
<string>We need access to the microphone to record your voice journal entries.</string>
```

### Step 5: Enable iCloud

1. Select your project → Target → **Signing & Capabilities**
2. Click **+ Capability**
3. Add **iCloud**
4. Check **CloudKit**
5. Create or select a CloudKit container:
   - Example: `iCloud.com.yourcompany.voicejournal`
   - **Important**: Use the same container ID for macOS app

### Step 6: Build and Run

1. Build the project (⌘B)
2. Run on a real device (voice features don't work well in simulator)
3. Grant microphone and speech recognition permissions when prompted
4. Start journaling!

## macOS Integration

### Step 1: Create Xcode Project

1. Open Xcode
2. Create new project: **File → New → Project**
3. Select **macOS → App**
4. Choose:
   - Interface: **SwiftUI**
   - Language: **Swift**

### Step 2: Add Package Dependencies

Add these packages individually as local packages:
1. Navigate to `VoiceJournal/VoiceJournalmacOS` and add it
2. Navigate to `VoiceJournal/VoiceJournalStorage` and add it

Note: The Core package will be added automatically as a dependency.

### Step 3: Update Your App File

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
            CommandGroup(replacing: .newItem) {
                Button("New Entry") {
                    // Custom new entry logic if needed
                }
                .keyboardShortcut("n", modifiers: .command)
            }
        }
    }
}
```

### Step 4: Add Info.plist Permissions

Same as iOS - add microphone and speech recognition descriptions.

### Step 5: Enable iCloud

1. **Signing & Capabilities** → Add **iCloud**
2. Check **CloudKit**
3. **Use the same CloudKit container as your iOS app**

### Step 6: Enable App Sandbox (if needed)

macOS apps may require App Sandbox:
1. **Signing & Capabilities** → **App Sandbox**
2. Enable:
   - **Incoming Connections (Server)**: Optional
   - **Outgoing Connections (Client)**: Required for iCloud
   - **User Selected File** (if allowing file imports)

### Step 7: Build and Run

1. Build (⌘B)
2. Run
3. Grant permissions
4. Entries sync with iOS/iPadOS via iCloud

## iCloud Sync Setup

### CloudKit Container

**Critical**: All platforms (iOS, iPadOS, macOS) must use the **same CloudKit container ID**.

1. In each app target, go to **Signing & Capabilities**
2. Under iCloud → CloudKit, select the same container
3. Format: `iCloud.com.yourcompany.voicejournal`

### How Sync Works

- **Journal Entries**: Synced via SwiftData + CloudKit automatically
- **Settings**: Synced via `NSUbiquitousKeyValueStore`
- **Conflict Resolution**: Handled automatically by SwiftData
- **Offline Support**: Changes queued until connection available

### Testing iCloud Sync

1. Build iOS and macOS apps with same CloudKit container
2. Sign in to same iCloud account on both devices
3. Create entry on iOS → should appear on macOS within seconds
4. Edit on macOS → changes sync to iOS
5. Check Settings → verify iCloud Sync is enabled

## Platform-Specific Features

### iOS
- Hold-to-record voice button
- Standard navigation
- Daily and weekly notifications

### iPadOS
- All iOS features plus:
- Apple Pencil with Scribble
- Drawing canvas (PencilKit)
- Side-by-side text and drawing
- Optimized for larger screen

### macOS
- Split view (sidebar + detail)
- Keyboard shortcuts:
  - ⌘N - New entry
  - ⌘S - Save (in entry view)
  - ⌘W - Close window
  - Esc - Cancel/dismiss
- Search in sidebar
- Native macOS UI patterns

## Troubleshooting

### Voice Recording Not Working

**Problem**: Microphone or speech recognition not available

**Solutions**:
- Check Info.plist has required permission keys
- Verify permissions granted in Settings/System Settings → Privacy
- Test on real device (not simulator)
- Check `voiceService.isAvailable` returns true

### Notifications Not Appearing

**Problem**: Notifications not showing

**Solutions**:
- Request permission via Settings view
- Check System Settings → Notifications → Your App
- Notifications don't appear when app is active (iOS)
- Test in background mode

### iCloud Sync Not Working

**Problem**: Entries not syncing between devices

**Solutions**:
- Verify same CloudKit container ID on all platforms
- Check signed in to same iCloud account
- Enable iCloud in Settings view (`iCloudSyncEnabled = true`)
- Check network connection
- Wait 10-30 seconds for initial sync
- Check Console app for CloudKit errors

### Apple Pencil Not Working (iPadOS)

**Problem**: Scribble not converting to text

**Solutions**:
- Enable Scribble in iPadOS Settings → Apple Pencil
- Ensure using `VoiceJournaliPadOSApp()` (not iOS version)
- iPad must support Apple Pencil
- Scribble only works on compatible iPads

### Build Errors

**Problem**: Package not found or import errors

**Solutions**:
- Verify package added correctly (File → Packages → Resolve Package Versions)
- Clean build folder (⌘⇧K)
- Restart Xcode
- Check Package.swift has correct paths

## Advanced Configuration

### Custom CloudKit Container

If you want to use a custom container:

1. Create container in CloudKit Dashboard
2. Update app capabilities to use your container
3. No code changes needed (SwiftData handles it)

### Disabling iCloud Sync

To disable iCloud sync:

```swift
// In Settings view, toggle off
settings.iCloudSyncEnabled = false
settings.save()

// Or create local-only container
let localContainer = ModelConfiguration(
    schema: schema,
    isStoredInMemoryOnly: false,
    cloudKitDatabase: .none  // Disable CloudKit
)
```

### Custom Summary Generation

To customize AI summaries:

1. Edit `SummaryService.swift` in VoiceJournalStorage package
2. Modify `generateSummaryText()` method
3. Add platform-specific Apple Intelligence integration

## Permissions Summary

| Permission | Platform | Purpose |
|------------|----------|---------|
| Microphone | All | Voice recording |
| Speech Recognition | All | Voice-to-text transcription |
| Notifications | All | Daily/weekly reminders |
| iCloud + CloudKit | All | Cross-device sync |

## Next Steps

1. ✅ Create Xcode project
2. ✅ Add package dependencies
3. ✅ Configure Info.plist
4. ✅ Enable iCloud + CloudKit
5. ✅ Build and test on device
6. ✅ Test sync between platforms
7. 🎨 Customize UI (optional)
8. 🚀 Submit to App Store

## Resources

- [CLAUDE.md](CLAUDE.md) - Architecture details
- [README.md](README.md) - Project overview
- Apple Documentation:
  - [SwiftData](https://developer.apple.com/documentation/swiftdata)
  - [CloudKit](https://developer.apple.com/documentation/cloudkit)
  - [Speech Framework](https://developer.apple.com/documentation/speech)
  - [PencilKit](https://developer.apple.com/documentation/pencilkit)
