// swift-tools-version:6.2

import PackageDescription

var dependencies: [Package.Dependency] = [
    .package(
        url: "https://github.com/apple/swift-argument-parser.git",
        from: "1.5.0"
    ),
]
var svgViewDependencies: [Target.Dependency] = []
var svgViewSwiftSettings: [SwiftSetting] = []

dependencies.append(
    .package(
        url: "https://github.com/GoodNotes/FoundationEssentialsExtras.git",
        revision: "dace29232ec271389cc1e4c4258c8162d1ac3f5f"
    )
)
dependencies.append(
    .package(
        url: "https://github.com/compnerd/xylem.git",
        revision: "9881c95ce3a139f4ccfa584676201516c2a5751d"
    )
)
svgViewDependencies.append(contentsOf: [
    .product(
        name: "FoundationEssentialsExtras",
        package: "FoundationEssentialsExtras",
        condition: .when(platforms: [.wasi])
    ),
    .product(
        name: "SAXParser",
        package: "xylem",
        condition: .when(platforms: [.wasi])
    ),
    .product(
        name: "XMLCore",
        package: "xylem",
        condition: .when(platforms: [.wasi])
    ),
])
svgViewSwiftSettings.append(
    .define(
        "FOUNDATION_ESSENTIALS_BUILD",
        .when(platforms: [.wasi])
    )
)

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
    dependencies: dependencies,
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
            dependencies: svgViewDependencies,
            path: "Source",
            swiftSettings: svgViewSwiftSettings
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
