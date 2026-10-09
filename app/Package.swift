// swift-tools-version:6.2
import PackageDescription

let package = Package(
    name: "ScreenGuide",
    platforms: [.macOS(.v26)],
    targets: [
        .executableTarget(
            name: "ScreenGuide",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
    ]
)
