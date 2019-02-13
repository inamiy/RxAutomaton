// swift-tools-version:4.2

import Foundation
import PackageDescription

let package = Package(
    name: "RxAutomaton",
    products: [
        .library(
            name: "RxAutomaton",
            targets: ["RxAutomaton"]),
    ],
    dependencies: [
        .package(url: "https://github.com/ReactiveX/RxSwift.git", from: "4.0.0"),
        .package(url: "https://github.com/Quick/Quick", from: "1.0.0"),
        .package(url: "https://github.com/Quick/Nimble", from: "7.0.0")
    ],
    targets: [
        .target(
            name: "RxAutomaton",
            dependencies: ["RxSwift", "RxCocoa"],
            path: "Sources"),
        .testTarget(
            name: "RxAutomatonTests",
            dependencies: ["RxAutomaton", "Quick", "Nimble"]),
    ]
)
