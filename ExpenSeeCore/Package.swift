// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ExpenSeeCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "ExpenSeeCore",
            targets: ["ExpenSeeCore"]
        )
    ],
    targets: [
        .target(
            name: "ExpenSeeCore",
            dependencies: [],
            path: "Sources/ExpenSeeCore"
        )
    ]
)