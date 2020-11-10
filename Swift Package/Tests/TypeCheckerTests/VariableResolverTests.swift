import Parser
import AST
import TestUtils

@testable import TypeChecker

import XCTest

class VariableResolverTests: XCTestCase {
  func testVariableResolverSuccess() {
    let sourceCode = """
      int x = 10
      while 1 < x {
        x = x - 1
      }
      """
    let parser = Parser(sourceCode: sourceCode)
    let unresolvedAst = try! parser.parseFile()
    
    let variableResolver = VariableResolver()
    XCTAssertNoThrow(try {
      let ast = try variableResolver.resolveVariables(in: unresolvedAst)
      
      let varX = SourceVariable(name: "x", disambiguationIndex: 1, type: .int)
      let declareStmt = VariableDeclStmt(variable: varX,
                                         expr: IntegerLiteralExpr(value: 10, range: .whatever),
                                         range: .whatever)
      
      let subExpr = BinaryOperatorExpr(lhs: VariableReferenceExpr(variable: .resolved(varX), range: .whatever),
                                       operator: .minus,
                                       rhs: IntegerLiteralExpr(value: 1, range: .whatever),
                                       range: .whatever)
      let assign = AssignStmt(variable: .resolved(varX),
                              expr: subExpr,
                              range: .whatever)
      let codeBlock = CodeBlockStmt(body: [assign], range: .whatever)
      let condition = BinaryOperatorExpr(lhs: IntegerLiteralExpr(value: 1, range: .whatever),
                                         operator: .lessThan,
                                         rhs: VariableReferenceExpr(variable: .resolved(varX), range: .whatever),
                                         range: .whatever)
      let whileStmt = WhileStmt(condition: condition, body: codeBlock, loopId: LoopId(id: 0), range: .whatever)
      let expected = TopLevelCodeStmt(stmts: [declareStmt, whileStmt], range: .whatever)
        
      XCTAssertEqualASTIgnoringRanges(ast, expected)
    }())
  }
  
  func testFindsUseBeforeDefine() {
    let sourceCode = "x = x - 1"
    let ast = try! Parser(sourceCode: sourceCode).parseFile()
    XCTAssertThrowsError(try VariableResolver().resolveVariables(in: ast))
  }
  
  func testFindsRecursiveVarDecl() {
    let sourceCode = "int x = x - 1"
    let ast = try! Parser(sourceCode: sourceCode).parseFile()
    XCTAssertThrowsError(try VariableResolver().resolveVariables(in: ast))
  }
  
  func testFindsDoubleDeclaration() {
    let sourceCode = """
      int x = 1
      int x = 2
      """
    let ast = try! Parser(sourceCode: sourceCode).parseFile()
    XCTAssertThrowsError(try VariableResolver().resolveVariables(in: ast))
  }
  
  func testVariableNotValidAfterBlock() {
    let sourceCode = """
      {
        int x = 1
      }
      x = x + 1
      """
    let ast = try! Parser(sourceCode: sourceCode).parseFile()
    XCTAssertThrowsError(try VariableResolver().resolveVariables(in: ast))
  }
  
  func testCanUseVariablesFromOuterScope() {
    let sourceCode = """
      int x = 1
      {
        x = x + 1
      }
      """
    let ast = try! Parser(sourceCode: sourceCode).parseFile()
    XCTAssertNoThrow(try VariableResolver().resolveVariables(in: ast))
  }
}
