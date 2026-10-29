// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "CmdBoard",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(name: "CmdBoard", path: "Sources/CmdBoard")
    ]
)
