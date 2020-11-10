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
    let unresolvedAst = try! Parser(sourceCode: sourceCode).parseFile()
    let resolvedAst = try! VariableResolver().resolveVariables(in: unresolvedAst)
    XCTAssertNoThrow(try TypeChecker().typeCheck(stmt: resolvedAst))
  }
  
  func testIfConditionCannotBeInt() {
    let sourceCode = "if 1 {}"
    let unresolvedAst = try! Parser(sourceCode: sourceCode).parseFile()
    let resolvedAst = try! VariableResolver().resolveVariables(in: unresolvedAst)
    XCTAssertThrowsError(try TypeChecker().typeCheck(stmt: resolvedAst))
  }
  
  func testWhileConditionCannotBeInt() {
    let sourceCode = "while 1 {}"
    let unresolvedAst = try! Parser(sourceCode: sourceCode).parseFile()
    let resolvedAst = try! VariableResolver().resolveVariables(in: unresolvedAst)
    XCTAssertThrowsError(try TypeChecker().typeCheck(stmt: resolvedAst))
  }
  
  func testObserverConditionCannotBeInt() {
    let sourceCode = "observe 1"
    let unresolvedAst = try! Parser(sourceCode: sourceCode).parseFile()
    let resolvedAst = try! VariableResolver().resolveVariables(in: unresolvedAst)
    XCTAssertThrowsError(try TypeChecker().typeCheck(stmt: resolvedAst))
  }
  
  func testCannotDeclareIntVariableWithBoolValue() {
    let sourceCode = "int x = 1 < 2"
    let unresolvedAst = try! Parser(sourceCode: sourceCode).parseFile()
    let resolvedAst = try! VariableResolver().resolveVariables(in: unresolvedAst)
    XCTAssertThrowsError(try TypeChecker().typeCheck(stmt: resolvedAst))
  }
  
  func testCannotAssignBoolToIntVariable() {
    let sourceCode = """
      int x = 1
      x = 1 < 2
      """
    let unresolvedAst = try! Parser(sourceCode: sourceCode).parseFile()
    let resolvedAst = try! VariableResolver().resolveVariables(in: unresolvedAst)
    XCTAssertThrowsError(try TypeChecker().typeCheck(stmt: resolvedAst))
  }
  
  func testTypeCheckerVisitsLoopBody() {
    let sourceCode = """
      while true {
        bool a = 2
      }
      """
    let unresolvedAst = try! Parser(sourceCode: sourceCode).parseFile()
    let resolvedAst = try! VariableResolver().resolveVariables(in: unresolvedAst)
    XCTAssertThrowsError(try TypeChecker().typeCheck(stmt: resolvedAst))
  }
}
