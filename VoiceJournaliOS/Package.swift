// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "VoiceJournaliOS",
    platforms: [
        .iOS(.v26),
        .macOS(.v26)
    ],
    products: [
        .library(
            name: "VoiceJournaliOS",
            targets: ["VoiceJournaliOS"]
        ),
    ],
    dependencies: [
        .package(path: "../VoiceJournalCore"),
        .package(path: "../VoiceJournalStorage")
    ],
    targets: [
        .target(
            name: "VoiceJournaliOS",
            dependencies: [
                "VoiceJournalCore",
                "VoiceJournalStorage"
            ]
        ),
    ]
)
