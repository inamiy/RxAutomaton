import PackageDescription

let package = Package(
    name: "RxAutomaton",
    dependencies: [
        .Package(url: "https://github.com/ReactiveX/RxSwift.git", majorVersion: 3)
    ]
)
