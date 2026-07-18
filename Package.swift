// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "TypingFarmerMac",
    defaultLocalization: "zh-Hans",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "TypingFarmerMac", targets: ["TypingFarmerMac"]),
        .executable(name: "TypingFarmerCoreSelfTest", targets: ["TypingFarmerCoreSelfTest"]),
        .executable(name: "TypingFarmerMacSupportSelfTest", targets: ["TypingFarmerMacSupportSelfTest"]),
        .library(name: "TypingFarmerCore", targets: ["TypingFarmerCore"]),
        .library(name: "TypingFarmerMacSupport", targets: ["TypingFarmerMacSupport"])
    ],
    targets: [
        .target(name: "TypingFarmerCore"),
        .target(
            name: "TypingFarmerMacSupport",
            dependencies: ["TypingFarmerCore"]
        ),
        .executableTarget(
            name: "TypingFarmerCoreSelfTest",
            dependencies: ["TypingFarmerCore"]
        ),
        .executableTarget(
            name: "TypingFarmerMacSupportSelfTest",
            dependencies: ["TypingFarmerMacSupport"]
        ),
        .executableTarget(
            name: "TypingFarmerMac",
            dependencies: ["TypingFarmerCore", "TypingFarmerMacSupport"],
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "TypingFarmerCoreTests",
            dependencies: ["TypingFarmerCore"]
        ),
        .testTarget(
            name: "TypingFarmerMacSupportTests",
            dependencies: ["TypingFarmerMacSupport"]
        )
    ],
    swiftLanguageModes: [.v5]
)
