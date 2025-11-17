// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "VoiceJournalmacOS",
    platforms: [
        .macOS(.v26)
    ],
    products: [
        .library(
            name: "VoiceJournalmacOS",
            targets: ["VoiceJournalmacOS"]
        ),
    ],
    dependencies: [
        .package(path: "../VoiceJournalCore"),
        .package(path: "../VoiceJournalStorage")
    ],
    targets: [
        .target(
            name: "VoiceJournalmacOS",
            dependencies: [
                "VoiceJournalCore",
                "VoiceJournalStorage"
            ]
        ),
    ]
)
