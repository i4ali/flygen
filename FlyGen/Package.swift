// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FlyGen",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "FlyGen",
            targets: ["FlyGen"]
        ),
    ],
    targets: [
        .target(
            name: "FlyGen",
            path: "FlyGen"
        ),
    ]
)
