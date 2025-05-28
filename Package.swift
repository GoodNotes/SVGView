// swift-tools-version:5.9

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
    ],
    targets: [
    	.target(
    		name: "SVGView",
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
    swiftLanguageVersions: [.v5]
)
