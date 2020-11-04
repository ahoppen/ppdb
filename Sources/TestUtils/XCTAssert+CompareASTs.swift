import AST
import XCTest

public extension SourceRange {
  /// Some range whoe value is not important because it will not be used when comparing ASTs using `equalsIgnoringRange`.
  static let whatever = SourceLocation(line: 0, column: 0, offset: "".startIndex)..<SourceLocation(line: 0, column: 0, offset: "".startIndex)
}

/// Check that the two ASTs are equal while ignoring their ranges.
public func XCTAssertEqualASTIgnoringRanges(_ lhs: ASTNode, _ rhs: ASTNode) {
  XCTAssert(lhs.equalsIgnoringRange(other: rhs), "\n\(lhs.debugDescription)\nis not equal to \n\n\(rhs.debugDescription)")
}

/// Check that the two ASTs are equal while ignoring their ranges.
public func XCTAssertEqualASTIgnoringRanges(_ lhs: [ASTNode], _ rhs: [ASTNode]) {
  XCTAssertEqual(lhs.count, rhs.count)
  for (lhs, rhs) in zip(lhs, rhs) {
    XCTAssertEqualASTIgnoringRanges(lhs, rhs)
  }
}
