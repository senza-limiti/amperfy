// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "WidgetSupport",
  products: [.library(name: "WidgetSupport", targets: ["WidgetSupport"])],
  targets: [
    .target(name: "WidgetSupport"),
    .testTarget(name: "WidgetSupportTests", dependencies: ["WidgetSupport"]),
  ]
)
