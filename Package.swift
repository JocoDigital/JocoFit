// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "JocoFit",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .tvOS(.v17)
    ],
    products: [
        .library(
            name: "JocoFit",
            targets: ["JocoFit"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/supabase/supabase-swift", from: "2.0.0")
    ],
    targets: [
        .target(
            name: "JocoFit",
            dependencies: [
                .product(name: "Supabase", package: "supabase-swift")
            ]
        ),
        .testTarget(
            name: "JocoFitTests",
            dependencies: ["JocoFit"]
        ),
    ]
)
