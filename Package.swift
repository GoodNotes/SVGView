// swift-tools-version:6.2

import PackageDescription

let package = Package(
	name: "SVGView",
    platforms: [
        .macOS(.v14),
        .iOS(.v14),
        .watchOS(.v7)
    ],
    products: [
    	.library(
    		name: "SVGView", 
    		targets: ["SVGView"]
    	),
        .executable(
            name: "GenerateReferencesCLI",
            targets: ["GenerateReferencesCLI"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/apple/swift-argument-parser.git",
            from: "1.5.0"
        ),
        .package(
            url: "https://github.com/GoodNotes/xylem.git",
            exact: "0.1.0-goodnotes-foundation-essentials"
        ),
    ],
    targets: [
        .executableTarget(
            name: "GenerateReferencesCLI",
            dependencies: [
                "SVGView",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            path: "GenerateReferencesCLI"
        ),
        .target(
            name: "SVGView",
            dependencies: [
                .product(
                    name: "SAXParser",
                    package: "xylem",
                    condition: .when(platforms: [.wasi, .linux, .android, .windows])
                ),
                .product(
                    name: "XMLCore",
                    package: "xylem",
                    condition: .when(platforms: [.wasi, .linux, .android, .windows])
                ),
            ],
            path: "Source"
        ),
        .testTarget(
            name: "CoreGraphicsPolyfillTests",
            dependencies: ["SVGView"]
        ),
        .testTarget(
            name: "SVGViewTests",
            dependencies: ["SVGView"],
            resources: [
                .copy("w3c")
            ]
        ),
    ],
    swiftLanguageModes: [.v5]
)
