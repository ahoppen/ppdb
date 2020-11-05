import AST
import Parser
import TypeChecker
import ExecutionHistory

import XCTest

fileprivate extension SourceRange {
  func sourceCode(in sourceCode: String) -> String {
    return String(sourceCode[lowerBound.offset..<upperBound.offset])
  }
}

class ExecutionHistoryTests: XCTestCase {
  private func parse(_ sourceCode: String) throws -> TopLevelCodeStmt {
    let parser = Parser(sourceCode: sourceCode)
    let ast = try parser.parseFile()
    return try TypeCheckPipeline.typeCheck(stmt: ast) as! TopLevelCodeStmt
  }
  
  func testGenerateAugmentedExecutionHistoryForStraightLineProgram() {
    XCTAssertNoThrow(try {
      let source = """
      int x = 5
      int y = 2
      int z = x + y
      """
      
      let ast = try parse(source)
      
      let executionHistory = ExecutionHistory(history: [.stepOver, .stepIntoTrue, .stepOver])
      
      let augmentedExecutionHistory = executionHistory.augmented(with: ast).history
      XCTAssertEqual(augmentedExecutionHistory.count, 3)
      XCTAssertEqual(augmentedExecutionHistory[0].command, .stepOver)
      XCTAssertEqual(augmentedExecutionHistory[0].stmt.range.sourceCode(in: source), "int x = 5")
      XCTAssertEqual(augmentedExecutionHistory[1].command, .stepIntoTrue)
      XCTAssertEqual(augmentedExecutionHistory[1].stmt.range.sourceCode(in: source), "int y = 2")
      XCTAssertEqual(augmentedExecutionHistory[2].command, .stepOver)
      XCTAssertEqual(augmentedExecutionHistory[2].stmt.range.sourceCode(in: source), "int z = x + y")
    }())
  }
  
  func testGenerateAugmentedExecutionHistoryForSteppedOverProbStatement() {
    XCTAssertNoThrow(try {
      let source = """
      int x = 5
      prob 0.5 { x = 2 }
      int y = 2
      """
      
      let ast = try parse(source)
      
      let executionHistory = ExecutionHistory(history: [.stepOver, .stepOver, .stepOver])
      
      let augmentedExecutionHistory = executionHistory.augmented(with: ast).history
      XCTAssertEqual(augmentedExecutionHistory.count, 3)
      XCTAssertEqual(augmentedExecutionHistory[0].command, .stepOver)
      XCTAssertEqual(augmentedExecutionHistory[0].stmt.range.sourceCode(in: source), "int x = 5")
      XCTAssertEqual(augmentedExecutionHistory[1].command, .stepOver)
      XCTAssertEqual(augmentedExecutionHistory[1].stmt.range.sourceCode(in: source), "prob 0.5 { x = 2 }")
      XCTAssertEqual(augmentedExecutionHistory[2].command, .stepOver)
      XCTAssertEqual(augmentedExecutionHistory[2].stmt.range.sourceCode(in: source), "int y = 2")
    }())
  }
  
  func testGenerateAugmentedExecutionHistoryForSteppedIntoTrueProbStatement() {
    XCTAssertNoThrow(try {
      let source = """
      int x = 5
      prob 0.5 { x = 2 }
      int y = 2
      """
      
      let ast = try parse(source)
      
      let executionHistory = ExecutionHistory(history: [.stepOver, .stepIntoTrue, .stepOver, .stepOver])
      
      let augmentedExecutionHistory = executionHistory.augmented(with: ast).history
      XCTAssertEqual(augmentedExecutionHistory.count, 4)
      XCTAssertEqual(augmentedExecutionHistory[0].command, .stepOver)
      XCTAssertEqual(augmentedExecutionHistory[0].stmt.range.sourceCode(in: source), "int x = 5")
      XCTAssertEqual(augmentedExecutionHistory[1].command, .stepIntoTrue)
      XCTAssertEqual(augmentedExecutionHistory[1].stmt.range.sourceCode(in: source), "prob 0.5 { x = 2 }")
      XCTAssertEqual(augmentedExecutionHistory[2].command, .stepOver)
      XCTAssertEqual(augmentedExecutionHistory[2].stmt.range.sourceCode(in: source), "x = 2")
      XCTAssertEqual(augmentedExecutionHistory[3].command, .stepOver)
      XCTAssertEqual(augmentedExecutionHistory[3].stmt.range.sourceCode(in: source), "int y = 2")
    }())
  }
  
  func testGenerateAugmentedExecutionHistoryForSteppedIntoFalseProbStatement() {
    XCTAssertNoThrow(try {
      let source = """
      int x = 5
      prob 0.5 { x = 2 }
      int y = 2
      """
      
      let ast = try parse(source)
      
      let executionHistory = ExecutionHistory(history: [.stepOver, .stepIntoFalse, .stepOver])
      
      let augmentedExecutionHistory = executionHistory.augmented(with: ast).history
      XCTAssertEqual(augmentedExecutionHistory.count, 3)
      XCTAssertEqual(augmentedExecutionHistory[0].command, .stepOver)
      XCTAssertEqual(augmentedExecutionHistory[0].stmt.range.sourceCode(in: source), "int x = 5")
      XCTAssertEqual(augmentedExecutionHistory[1].command, .stepIntoFalse)
      XCTAssertEqual(augmentedExecutionHistory[1].stmt.range.sourceCode(in: source), "prob 0.5 { x = 2 }")
      XCTAssertEqual(augmentedExecutionHistory[2].command, .stepOver)
      XCTAssertEqual(augmentedExecutionHistory[2].stmt.range.sourceCode(in: source), "int y = 2")
    }())
  }
  
  func testGenerateAugmentedExecutionHistoryForLoop() {
    XCTAssertNoThrow(try {
      let source = """
      int x = 5
      while 0 < x { x = x - 1 }
      int y = 2
      """
      
      let ast = try parse(source)
      
      let executionHistory = ExecutionHistory(history: [.stepOver, .stepIntoTrue, .stepOver, .stepOver])
      
      let augmentedExecutionHistory = executionHistory.augmented(with: ast).history
      XCTAssertEqual(augmentedExecutionHistory.count, 4)
      XCTAssertEqual(augmentedExecutionHistory[0].command, .stepOver)
      XCTAssertEqual(augmentedExecutionHistory[0].stmt.range.sourceCode(in: source), "int x = 5")
      XCTAssertEqual(augmentedExecutionHistory[1].command, .stepIntoTrue)
      XCTAssertEqual(augmentedExecutionHistory[1].stmt.range.sourceCode(in: source), "while 0 < x { x = x - 1 }")
      XCTAssertEqual(augmentedExecutionHistory[2].command, .stepOver)
      XCTAssertEqual(augmentedExecutionHistory[2].stmt.range.sourceCode(in: source), "x = x - 1")
      XCTAssertEqual(augmentedExecutionHistory[3].command, .stepOver)
      XCTAssertEqual(augmentedExecutionHistory[3].stmt.range.sourceCode(in: source), "while 0 < x { x = x - 1 }")
    }())
  }
}
