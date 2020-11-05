import Execution
import AST
import Parser
import TypeChecker
import TestUtils

import XCTest

class HistoryExecutorTests: XCTestCase {
  private func parse(_ sourceCode: String) throws -> Stmt {
    let parser = Parser(sourceCode: sourceCode)
    let ast = try parser.parseFile()
    return try TypeCheckPipeline.typeCheck(stmt: ast)
  }

  func testExecuteMultiStatementProgram() {
    XCTAssertNoThrow(try {
      let source = """
        int x = 5
        int y = 2
        int z = x + y
        """
      let varX = SourceVariable(name: "x", disambiguationIndex: 1, type: .int)
      let varY = SourceVariable(name: "y", disambiguationIndex: 1, type: .int)
      let varZ = SourceVariable(name: "z", disambiguationIndex: 1, type: .int)
      
      let ast = try parse(source) as! TopLevelCodeStmt
      
      let samples1StepOver = HistoryExecutor.execute(history: [.stepOver], ast: ast, numSamples: 1)
      XCTAssertEqual(samples1StepOver.count, 1)
      XCTAssertEqual(samples1StepOver[0].values[varX]?.integer, 5)
      
      let samples2StepOver = HistoryExecutor.execute(history: [.stepOver, .stepOver], ast: ast, numSamples: 1)
      XCTAssertEqual(samples2StepOver.count, 1)
      XCTAssertEqual(samples2StepOver[0].values[varX]?.integer, 5)
      XCTAssertEqual(samples2StepOver[0].values[varY]?.integer, 2)
      
      let samples3StepOver = HistoryExecutor.execute(history: [.stepOver, .stepOver, .stepOver], ast: ast, numSamples: 1)
      XCTAssertEqual(samples3StepOver.count, 1)
      XCTAssertEqual(samples3StepOver[0].values[varX]?.integer, 5)
      XCTAssertEqual(samples3StepOver[0].values[varY]?.integer, 2)
      XCTAssertEqual(samples3StepOver[0].values[varZ]?.integer, 7)
    }())
  }
}
