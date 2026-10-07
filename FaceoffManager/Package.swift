// swift-tools-version:5.9
// Nur für die automatischen Tests der Spiellogik (Terminal: `swift test` in diesem Ordner).
// Die App selbst wird über das Xcode-Projekt gebaut, siehe README.md.
import PackageDescription

let package = Package(
    name: "FaceoffCore",
    platforms: [.macOS(.v14), .iOS(.v17)],
    targets: [
        .target(name: "FaceoffCore", path: "Game/Core"),
        .testTarget(name: "FaceoffCoreTests", dependencies: ["FaceoffCore"], path: "Tests/FaceoffCoreTests")
    ]
)
