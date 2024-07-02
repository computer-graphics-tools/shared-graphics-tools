// swift-tools-version:5.9

import PackageDescription
let package = Package(
    name: "shared-graphics-tools",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .macCatalyst(.v13)
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
            .upToNextMinor(from: "1.3.1")
        ),
        .package(
            url: "https://github.com/eugenebokhan/core-video-tools.git",
            .upToNextMinor(from: "0.1.0")
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
        ),
        .testTarget(
            name: "SharedGraphicsToolsTests",
            dependencies: [
                .target(name: "SharedGraphicsTools"),
                .product(name: "MetalComputeTools", package: "metal-tools")
            ]
        )
    ]
)
