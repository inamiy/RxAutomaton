// swift-tools-version:5.0

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
        .package(url: "https://github.com/ReactiveX/RxSwift.git", from: "6.2.0"),
    ],
    targets: [
        .target(
            name: "RxAutomaton",
            dependencies: ["RxSwift", "RxCocoa", "RxRelay"],
            path: "Sources"),
    ]
)

// `$ RXAUTOMATON_SPM_TEST=1 swift test`
if ProcessInfo.processInfo.environment.keys.contains("RXAUTOMATON_SPM_TEST") {
    package.targets.append(
        .testTarget(
            name: "RxAutomatonTests",
            dependencies: ["RxAutomaton", "RxTest", "Quick", "Nimble"])
    )

    package.dependencies.append(
        contentsOf: [
            .package(url: "https://github.com/Quick/Quick.git", from: "4.0.0"),
            .package(url: "https://github.com/Quick/Nimble.git", from: "9.2.0"),
        ]
    )
}
