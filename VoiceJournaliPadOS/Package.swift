// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "VoiceJournaliPadOS",
    platforms: [
        .iOS(.v26), // iPadOS uses iOS platform
        .macOS(.v26)
    ],
    products: [
        .library(
            name: "VoiceJournaliPadOS",
            targets: ["VoiceJournaliPadOS"]
        ),
    ],
    dependencies: [
        .package(path: "../VoiceJournalCore"),
        .package(path: "../VoiceJournalStorage"),
        .package(path: "../VoiceJournaliOS")
    ],
    targets: [
        .target(
            name: "VoiceJournaliPadOS",
            dependencies: [
                "VoiceJournalCore",
                "VoiceJournalStorage",
                "VoiceJournaliOS"
            ]
        ),
    ]
)
