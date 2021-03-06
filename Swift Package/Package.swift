// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "ppdb",
  
  // MARK: - Products
  
  products: [
    .executable(name: "ppdb", targets: ["DebuggerConsole"]),
    .library(name: "libppdb", targets: ["AST", "Execution", "ExecutionHistory", "Parser", "TypeChecker", "WPInference"]),
  ],
  
  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser", from: "0.0.1"),
  ],
  
  // MARK: - Targets
  
  targets: [
    .target(
      name: "AST",
      dependencies: [
        "Utils"
      ]
    ),
    .target(
      name: "Debugger",
      dependencies: [
        "AST",
        "Execution",
        "ExecutionHistory",
        "Parser",
        "TypeChecker",
        "WPInference",
        "Utils",
      ]
    ),
    .target(
      name: "DebuggerConsole",
      dependencies: [
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
        "Debugger"
      ]
    ),
    .target(
      name: "Execution",
      dependencies: [
        "AST",
        "ExecutionHistory",
        "Utils",
      ]
    ),
    .target(
      name: "ExecutionHistory",
      dependencies: [
        "AST",
      ]
    ),
    .target(
      name: "Parser",
      dependencies: [
        "AST"
    ]),
    .target(
      name: "TypeChecker",
      dependencies: [
        "AST",
        "Parser",
    ]),
    .target(
      name: "TestUtils",
      dependencies: [
        "AST"
      ]
    ),
    .target(
      name: "Utils",
      dependencies: []
    ),
    .target(
      name: "WPInference",
      dependencies: [
        "AST",
        "ExecutionHistory",
        "Utils",
      ]
    ),
    
    // MARK: - Test targets
    
    .testTarget(
      name: "ASTTests",
      dependencies: [
        "AST",
        "TestUtils",
      ]
    ),
    .testTarget(
      name: "DebuggerTests",
      dependencies: [
        "AST",
        "Debugger",
        "ExecutionHistory",
        "TestUtils",
      ]
    ),
    .testTarget(
      name: "ExecutionTests",
      dependencies: [
        "Execution",
        "AST",
        "Parser",
        "TypeChecker",
        "TestUtils",
      ]
    ),
    .testTarget(
      name: "ExecutionHistoryTests",
      dependencies: [
        "AST",
        "ExecutionHistory",
        "Parser",
        "TypeChecker",
        "TestUtils",
      ]
    ),
    .testTarget(
      name: "ParserTests",
      dependencies: [
        "AST",
        "Parser",
        "TestUtils",
      ]
    ),
    .testTarget(
      name: "TypeCheckerTests",
      dependencies: [
        "AST",
        "Parser",
        "TypeChecker",
        "TestUtils",
      ]
    ),
    .testTarget(
      name: "WPInferenceTests",
      dependencies: [
        "AST",
        "Parser",
        "TypeChecker",
        "TestUtils",
        "WPInference",
      ]
    ),
  ]
)
