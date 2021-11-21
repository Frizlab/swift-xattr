// swift-tools-version:5.5
import PackageDescription


let package = Package(
	name: "swift-xattr",
	platforms: [.macOS(.v11)],
	products: [
		.library(name: "Xattr", targets: ["Xattr"])
	],
	targets: [
		.target(name: "Xattr")
	]
)
