// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "BarkExample",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        .package(name: "bark-ffi", path: "../../..")
    ],
    targets: [
        .executableTarget(
            name: "BarkExample",
            dependencies: [
                .product(name: "Bark", package: "bark-ffi")
            ],
            path: "Sources"
        )
    ]
)
