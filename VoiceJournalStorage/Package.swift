// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "VoiceJournalStorage",
    platforms: [
        .iOS(.v26),
        .macOS(.v26)
    ],
    products: [
        .library(
            name: "VoiceJournalStorage",
            targets: ["VoiceJournalStorage"]
        ),
    ],
    dependencies: [
        .package(path: "../VoiceJournalCore")
    ],
    targets: [
        .target(
            name: "VoiceJournalStorage",
            dependencies: ["VoiceJournalCore"]
        ),
    ]
)
