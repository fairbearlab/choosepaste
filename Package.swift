// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ChoosePaste",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "ChoosePaste",
            path: "ChoosePaste",
            exclude: ["Resources"],
            linkerSettings: [
                .linkedFramework("Carbon"),
            ]
        )
    ]
)
