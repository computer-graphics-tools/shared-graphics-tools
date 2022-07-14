// swift-tools-version:5.3

import PackageDescription
let package = Package(
    name: "shared-graphics-tools",
    platforms: [
        .iOS(.v12),
        .macOS(.v11)
    ],
    products: [
        .library(
            name: "SharedGraphicsTools",
            targets: ["SharedGraphicsTools"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/eugenebokhan/metal-tools.git",
            .upToNextMinor(from: "1.0.11")
        ),
        .package(
            url: "https://github.com/eugenebokhan/core-video-tools.git",
            .upToNextMinor(from: "0.0.6")
        )
    ],
    targets: [
        .target(
            name: "SharedGraphicsTools",
            dependencies: [
                .product(
                    name: "MetalTools",
                    package: "metal-tools"
                ),
                .product(
                    name: "CoreVideoTools",
                    package: "core-video-tools"
                )
            ]
        )
    ]
)
