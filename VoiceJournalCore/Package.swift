// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "VoiceJournalCore",
    platforms: [
        .iOS(.v26),
        .macOS(.v26)
    ],
    products: [
        .library(
            name: "VoiceJournalCore",
            targets: ["VoiceJournalCore"]
        ),
    ],
    targets: [
        .target(
            name: "VoiceJournalCore"
        ),
    ]
)
