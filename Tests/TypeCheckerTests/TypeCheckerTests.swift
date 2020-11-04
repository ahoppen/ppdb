import Parser

@testable import TypeChecker

import XCTest

class TypeCheckerTests: XCTestCase {
  func testTypeCheckerSuccess() {
    let sourceCode = """
      int x = 10
      while 1 < x {
        x = x - 1
      }
      observe(x == 0)
      """
    let unresolvedStmts = try! Parser(sourceCode: sourceCode).parseFile()
    let resolvedStmts = try! VariableResolver().resolveVariables(in: unresolvedStmts)
    XCTAssertNoThrow(try TypeChecker().typeCheck(stmts: resolvedStmts))
  }
  
  func testIfConditionCannotBeInt() {
    let sourceCode = "if 1 {}"
    let unresolvedStmts = try! Parser(sourceCode: sourceCode).parseFile()
    let resolvedStmts = try! VariableResolver().resolveVariables(in: unresolvedStmts)
    XCTAssertThrowsError(try TypeChecker().typeCheck(stmts: resolvedStmts))
  }
  
  func testWhileConditionCannotBeInt() {
    let sourceCode = "while 1 {}"
    let unresolvedStmts = try! Parser(sourceCode: sourceCode).parseFile()
    let resolvedStmts = try! VariableResolver().resolveVariables(in: unresolvedStmts)
    XCTAssertThrowsError(try TypeChecker().typeCheck(stmts: resolvedStmts))
  }
  
  func testObserverConditionCannotBeInt() {
    let sourceCode = "observe 1"
    let unresolvedStmts = try! Parser(sourceCode: sourceCode).parseFile()
    let resolvedStmts = try! VariableResolver().resolveVariables(in: unresolvedStmts)
    XCTAssertThrowsError(try TypeChecker().typeCheck(stmts: resolvedStmts))
  }
  
  func testCannotDeclareIntVariableWithBoolValue() {
    let sourceCode = "int x = 1 < 2"
    let unresolvedStmts = try! Parser(sourceCode: sourceCode).parseFile()
    let resolvedStmts = try! VariableResolver().resolveVariables(in: unresolvedStmts)
    XCTAssertThrowsError(try TypeChecker().typeCheck(stmts: resolvedStmts))
  }
  
  func testCannotAssignBoolToIntVariable() {
    let sourceCode = """
      int x = 1
      x = 1 < 2
      """
    let unresolvedStmts = try! Parser(sourceCode: sourceCode).parseFile()
    let resolvedStmts = try! VariableResolver().resolveVariables(in: unresolvedStmts)
    XCTAssertThrowsError(try TypeChecker().typeCheck(stmts: resolvedStmts))
  }
  
  func testTypeCheckerVisitsLoopBody() {
    let sourceCode = """
      while true {
        bool a = 2
      }
      """
    let unresolvedStmts = try! Parser(sourceCode: sourceCode).parseFile()
    let resolvedStmts = try! VariableResolver().resolveVariables(in: unresolvedStmts)
    XCTAssertThrowsError(try TypeChecker().typeCheck(stmts: resolvedStmts))
  }
}
