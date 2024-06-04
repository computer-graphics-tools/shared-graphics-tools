// swift-tools-version:5.6

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
        .package(url: "https://github.com/eugenebokhan/metal-tools.git", exact: "1.2.0"),
        .package(url: "https://github.com/eugenebokhan/core-video-tools.git", exact: "0.0.6")
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
            ]
        )
    ]
)
