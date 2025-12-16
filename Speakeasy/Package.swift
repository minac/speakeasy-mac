// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Speakeasy",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "Speakeasy",
            targets: ["Speakeasy"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.6.0")
    ],
    targets: [
        .executableTarget(
            name: "Speakeasy",
            dependencies: ["SwiftSoup"],
            path: "Speakeasy",
            exclude: ["Resources/Info.plist"]
        ),
        .testTarget(
            name: "SpeakeasyTests",
            dependencies: ["Speakeasy"],
            path: "Tests"
        )
    ]
)
