import AST
import TestUtils

@testable import Parser

import XCTest


class ParserTests: XCTestCase {
  func testSimpleExpr() {
    XCTAssertNoThrow(try {
      let expr = "1 + 2"
      let parser = Parser(sourceCode: expr)
      let ast = try parser.parseExpr()
      let expectedAst = BinaryOperatorExpr(lhs: IntegerLiteralExpr(value: 1, range: .whatever),
                                           operator: .plus,
                                           rhs: IntegerLiteralExpr(value: 2, range: .whatever),
                                           range: .whatever)
      XCTAssertEqualASTIgnoringRanges(ast, expectedAst)
    }())
  }
  
  func testExprWithThreeTerms() {
    XCTAssertNoThrow(try {
      let expr = "1 + 2 + 3"
      let parser = Parser(sourceCode: expr)
      let ast = try parser.parseExpr()
      let onePlusTwo = BinaryOperatorExpr(lhs: IntegerLiteralExpr(value: 1, range: .whatever),
                                          operator: .plus,
                                          rhs: IntegerLiteralExpr(value: 2, range: .whatever),
                                          range: .whatever)
      let expectedAst = BinaryOperatorExpr(lhs: onePlusTwo,
                                           operator: .plus,
                                           rhs: IntegerLiteralExpr(value: 3, range: .whatever),
                                           range: .whatever)
      XCTAssertEqualASTIgnoringRanges(ast, expectedAst)
    }())
  }
  
  func testExprWithPrecedence() {
    XCTAssertNoThrow(try {
      let expr = "1 + 2 < 3"
      let parser = Parser(sourceCode: expr)
      let ast = try parser.parseExpr()
      let onePlusTwo = BinaryOperatorExpr(lhs: IntegerLiteralExpr(value: 1, range: .whatever),
                                          operator: .plus,
                                          rhs: IntegerLiteralExpr(value: 2, range: .whatever),
                                          range: .whatever)
      let expectedAst = BinaryOperatorExpr(lhs: onePlusTwo,
                                           operator: .lessThan,
                                           rhs: IntegerLiteralExpr(value: 3, range: .whatever),
                                           range: .whatever)
      XCTAssertEqualASTIgnoringRanges(ast, expectedAst)
    }())
  }
  
  func testSingleIdentifier() {
    XCTAssertNoThrow(try {
      let parser = Parser(sourceCode: "x")
      let ast = try parser.parseExpr()
      let expectedAst = VariableReferenceExpr(variable: .unresolved(name: "x"), range: .whatever)
      
      XCTAssertEqualASTIgnoringRanges(ast, expectedAst)
    }())
  }
  
  func testParenthesisAtEnd() {
    XCTAssertNoThrow(try {
      let expr = "1 + (2 + 3)"
      let parser = Parser(sourceCode: expr)
      let ast = try parser.parseExpr()
      let twoPlusThree = BinaryOperatorExpr(lhs: IntegerLiteralExpr(value: 2, range: .whatever),
                                            operator: .plus,
                                            rhs: IntegerLiteralExpr(value: 3, range: .whatever),
                                            range: .whatever)
      let expectedAst = BinaryOperatorExpr(lhs: IntegerLiteralExpr(value: 1, range: .whatever),
                                           operator: .plus,
                                           rhs: ParenExpr(subExpr: twoPlusThree, range: .whatever),
                                           range: .whatever)
      
      XCTAssertEqualASTIgnoringRanges(ast, expectedAst)
    }())
  }
  
  func testParenthesisAtStart() {
    XCTAssertNoThrow(try {
      let expr = "(1 + 2) + 3"
      let parser = Parser(sourceCode: expr)
      let ast = try parser.parseExpr()
      let onePlusTwo = BinaryOperatorExpr(lhs: IntegerLiteralExpr(value: 1, range: .whatever),
                                          operator: .plus,
                                          rhs: IntegerLiteralExpr(value: 2, range: .whatever),
                                          range: .whatever)
      let expectedAst = BinaryOperatorExpr(lhs: ParenExpr(subExpr: onePlusTwo, range: .whatever),
                                           operator: .plus,
                                           rhs: IntegerLiteralExpr(value: 3, range: .whatever),
                                           range: .whatever)
      XCTAssertEqualASTIgnoringRanges(ast, expectedAst)
    }())
  }
  
//  func testDiscreteIntegerDistribution() {
//    XCTAssertNoThrow(try {
//      let expr = "discrete({1: 0.2, 2: 0.8})"
//      let parser = Parser(sourceCode: expr)
//      let ast = try parser.parseExpr()
//      let distribution = DiscreteIntegerDistributionExpr(distribution: [
//        1: 0.2,
//        2: 0.8
//      ], range: .whatever)
//      XCTAssertEqualASTIgnoringRanges(ast, distribution)
//    }())
//  }
  
  func testParseVariableDeclaration() {
    XCTAssertNoThrow(try {
      let stmt = "int x = y + 2"
      let parser = Parser(sourceCode: stmt)
      let ast = try parser.parseStmt()
      
      let expr = BinaryOperatorExpr(lhs: VariableReferenceExpr(variable: .unresolved(name: "y"), range: .whatever),
                                    operator: .plus,
                                    rhs: IntegerLiteralExpr(value: 2, range: .whatever),
                                    range: .whatever)
      
      let declExpr = VariableDeclStmt(variable: SourceVariable(name: "x", disambiguationIndex: 1, type: .int),
                                      expr: expr,
                                      range: .whatever)
      
      XCTAssertNotNil(ast)
      XCTAssertEqualASTIgnoringRanges(ast!, declExpr)
    }())
  }
  
  func testVariableAssignemnt() {
    XCTAssertNoThrow(try {
      let stmt = "x = x + 1"
      let parser = Parser(sourceCode: stmt)
      let ast = try parser.parseStmt()
      
      let expr = BinaryOperatorExpr(lhs: VariableReferenceExpr(variable: .unresolved(name: "x"), range: .whatever),
                                    operator: .plus,
                                    rhs: IntegerLiteralExpr(value: 1, range: .whatever),
                                    range: .whatever)
      
      let declExpr = AssignStmt(variable: .unresolved(name: "x"),
                                expr: expr,
                                range: .whatever)
      
      XCTAssertNotNil(ast)
      XCTAssertEqualASTIgnoringRanges(ast!, declExpr)
    }())
  }
  
  func testParseIfStmt() {
    XCTAssertNoThrow(try {
      let sourceCode = """
      if x == 1 {
        int y = 2
        y = y + 1
      }
      """
      let parser = Parser(sourceCode: sourceCode)
      let ast = try parser.parseStmt()
      
      let varDecl = VariableDeclStmt(variable: SourceVariable(name: "y", disambiguationIndex: 1, type: .int),
                                     expr: IntegerLiteralExpr(value: 2, range: .whatever),
                                     range: .whatever)
      let addExpr = BinaryOperatorExpr(lhs: VariableReferenceExpr(variable: .unresolved(name: "y"), range: .whatever),
                                       operator: .plus,
                                       rhs: IntegerLiteralExpr(value: 1, range: .whatever),
                                       range: .whatever)
      let assign = AssignStmt(variable: .unresolved(name: "y"),
                              expr: addExpr,
                              range: .whatever)
      let codeBlock = CodeBlockStmt(body: [varDecl, assign], range: .whatever)
      let condition = BinaryOperatorExpr(lhs: VariableReferenceExpr(variable: .unresolved(name: "x"), range: .whatever),
                                         operator: .equal,
                                         rhs: IntegerLiteralExpr(value: 1, range: .whatever),
                                         range: .whatever)
      let ifStmt = IfStmt(condition: condition, ifBody: codeBlock, elseBody: nil, range: .whatever)
      XCTAssertEqualASTIgnoringRanges(ast!, ifStmt)
    }())
  }
  
  func testParseIfStmtWithParanthesInCondition() {
    XCTAssertNoThrow(try {
      let sourceCode = """
      if (x == 1) {
        int y = 2
        y = y + 1
      }
      """
      let parser = Parser(sourceCode: sourceCode)
      let ast = try parser.parseStmt()
      
      let varDecl = VariableDeclStmt(variable: SourceVariable(name: "y", disambiguationIndex: 1, type: .int),
                                     expr: IntegerLiteralExpr(value: 2, range: .whatever),
                                     range: .whatever)
      let addExpr = BinaryOperatorExpr(lhs: VariableReferenceExpr(variable: .unresolved(name: "y"), range: .whatever),
                                       operator: .plus,
                                       rhs: IntegerLiteralExpr(value: 1, range: .whatever),
                                       range: .whatever)
      let assign = AssignStmt(variable: .unresolved(name: "y"),
                              expr: addExpr,
                              range: .whatever)
      let codeBlock = CodeBlockStmt(body: [varDecl, assign], range: .whatever)
      let condition = BinaryOperatorExpr(lhs: VariableReferenceExpr(variable: .unresolved(name: "x"), range: .whatever),
                                         operator: .equal,
                                         rhs: IntegerLiteralExpr(value: 1, range: .whatever),
                                         range: .whatever)
      let parenCondition = ParenExpr(subExpr: condition, range: .whatever)
      let ifStmt = IfStmt(condition: parenCondition, ifBody: codeBlock, elseBody: nil, range: .whatever)
      XCTAssertEqualASTIgnoringRanges(ast!, ifStmt)
    }())
  }
  
  func testParseWhileStmt() {
    XCTAssertNoThrow(try {
      let sourceCode = """
      while 1 < x {
        x = x - 1
      }
      """
      let parser = Parser(sourceCode: sourceCode)
      let ast = try parser.parseStmt()
      
      let subExpr = BinaryOperatorExpr(lhs: VariableReferenceExpr(variable: .unresolved(name: "x"), range: .whatever),
                                       operator: .minus,
                                       rhs: IntegerLiteralExpr(value: 1, range: .whatever),
                                       range: .whatever)
      let assign = AssignStmt(variable: .unresolved(name: "x"),
                              expr: subExpr,
                              range: .whatever)
      let codeBlock = CodeBlockStmt(body: [assign], range: .whatever)
      let condition = BinaryOperatorExpr(lhs: IntegerLiteralExpr(value: 1, range: .whatever),
                                         operator: .lessThan,
                                         rhs: VariableReferenceExpr(variable: .unresolved(name: "x"), range: .whatever),
                                         range: .whatever)
      let whileStmt = WhileStmt(condition: condition, body: codeBlock, loopId: LoopId(id: 0), range: .whatever)
      XCTAssertEqualASTIgnoringRanges(ast!, whileStmt)
    }())
  }
  
  func testParseObserveWithoutParan() {
    XCTAssertNoThrow(try {
      let stmt = "observe x < 0"
      let parser = Parser(sourceCode: stmt)
      let ast = try parser.parseStmt()
      
      let condition = BinaryOperatorExpr(lhs: VariableReferenceExpr(variable: .unresolved(name: "x"), range: .whatever),
                                         operator: .lessThan,
                                         rhs: IntegerLiteralExpr(value: 0, range: .whatever),
                                         range: .whatever)
      let observeStmt = ObserveStmt(condition: condition, range: .whatever)
      
      XCTAssertEqualASTIgnoringRanges(ast!, observeStmt)
    }())
  }
  
  func testParseObserveWithParan() {
    XCTAssertNoThrow(try {
      let stmt = "observe(x < 0)"
      let parser = Parser(sourceCode: stmt)
      let ast = try parser.parseStmt()
      
      let condition = BinaryOperatorExpr(lhs: VariableReferenceExpr(variable: .unresolved(name: "x"), range: .whatever),
                                         operator: .lessThan,
                                         rhs: IntegerLiteralExpr(value: 0, range: .whatever),
                                         range: .whatever)
      let parenCondition = ParenExpr(subExpr: condition, range: .whatever)
      let observeStmt = ObserveStmt(condition: parenCondition, range: .whatever)
      
      XCTAssertEqualASTIgnoringRanges(ast!, observeStmt)
    }())
  }
  
  func testParseEmptyCodeBlock() {
    XCTAssertNoThrow(try {
      let parser = Parser.init(sourceCode: "{}")
      let ast = try parser.parseStmt()
      
      let codeBlock = CodeBlockStmt(body: [], range: .whatever)
      XCTAssertEqualASTIgnoringRanges(ast!, codeBlock)
    }())
  }
  
  func testParseProbStmtWithoutElseBody() {
    XCTAssertNoThrow(try {
      let parser = Parser(sourceCode: """
      int a = 0
      prob 0.5 {
        a = 1
      }
      """)
      let ast = try parser.parseFile()
      
      let aDecl = VariableDeclStmt(variable: SourceVariable(name: "a", disambiguationIndex: 1, type: .int),
                                   expr: IntegerLiteralExpr(value: 0, range: .whatever),
                                   range: .whatever
      )
      let aAssignment = AssignStmt(
        variable: .unresolved(name: "a"),
        expr: IntegerLiteralExpr(value: 1, range: .whatever),
        range: .whatever
      )
      let probStmt = ProbStmt(condition: FloatLiteralExpr(value: 0.5, range: .whatever),
                              ifBody: CodeBlockStmt(body: [aAssignment], range: .whatever),
                              elseBody: nil,
                              range: .whatever
      )
      let expected = TopLevelCodeStmt(stmts: [aDecl, probStmt], range: .whatever)
      
      XCTAssertEqualASTIgnoringRanges(ast, expected)
    }())
  }
  
  func testParseProbStmtWithElseBody() {
    XCTAssertNoThrow(try {
      let parser = Parser(sourceCode: """
      int a = 0
      prob 0.5 {
        a = 1
      } else {
        a = 2
      }
      """)
      let ast = try parser.parseFile()
      
      let aDecl = VariableDeclStmt(variable: SourceVariable(name: "a", disambiguationIndex: 1, type: .int),
                                   expr: IntegerLiteralExpr(value: 0, range: .whatever),
                                   range: .whatever
      )
      let aAssignmentTo1 = AssignStmt(
        variable: .unresolved(name: "a"),
        expr: IntegerLiteralExpr(value: 1, range: .whatever),
        range: .whatever
      )
      let aAssignmentTo2 = AssignStmt(
        variable: .unresolved(name: "a"),
        expr: IntegerLiteralExpr(value: 2, range: .whatever),
        range: .whatever
      )
      let probStmt = ProbStmt(condition: FloatLiteralExpr(value: 0.5, range: .whatever),
                              ifBody: CodeBlockStmt(body: [aAssignmentTo1], range: .whatever),
                              elseBody: CodeBlockStmt(body: [aAssignmentTo2], range: .whatever),
                              range: .whatever
      )
      let expected = TopLevelCodeStmt(stmts: [aDecl, probStmt], range: .whatever)
      
      XCTAssertEqualASTIgnoringRanges(ast, expected)
    }())
  }
  
  func testParseFileWithoutSemicolons() {
    XCTAssertNoThrow(try {
      let parser = Parser.init(sourceCode: """
      int a = 1
      int b = 2
      int c = a + b
      observe 0 < c
      """)
      let ast = try parser.parseFile()

      let aDecl = VariableDeclStmt(variable: SourceVariable(name: "a", disambiguationIndex: 1, type: .int),
                                   expr: IntegerLiteralExpr(value: 1, range: .whatever),
                                   range: .whatever)
      let bDecl = VariableDeclStmt(variable: SourceVariable(name: "b", disambiguationIndex: 1, type: .int),
                                   expr: IntegerLiteralExpr(value: 2, range: .whatever),
                                   range: .whatever)
      let addition = BinaryOperatorExpr(lhs: VariableReferenceExpr(variable: .unresolved(name: "a"), range: .whatever),
                                        operator: .plus,
                                        rhs: VariableReferenceExpr(variable: .unresolved(name: "b"), range: .whatever),
                                        range: .whatever)
      let cDecl = VariableDeclStmt(variable: SourceVariable(name: "c", disambiguationIndex: 1, type: .int),
                                   expr: addition,
                                   range: .whatever)
      let observeCondition = BinaryOperatorExpr(lhs: IntegerLiteralExpr(value: 0, range: .whatever),
                                                operator: .lessThan,
                                                rhs: VariableReferenceExpr(variable: .unresolved(name: "c"), range: .whatever),
                                                range: .whatever)
      let observeStmt = ObserveStmt(condition: observeCondition, range: .whatever)

      let expected = TopLevelCodeStmt(stmts: [aDecl, bDecl, cDecl, observeStmt], range: .whatever)

      XCTAssertEqualASTIgnoringRanges(ast, expected)
    }())
  }

  func testParseFileWithSemicolons() {
    XCTAssertNoThrow(try {
      let parser = Parser.init(sourceCode: """
      int a = 1;
      int b = 2;
      int c = a + b;
      observe(0 < c);
      """)
      let ast = try parser.parseFile()

      let aDecl = VariableDeclStmt(variable: SourceVariable(name: "a", disambiguationIndex: 1, type: .int),
                                   expr: IntegerLiteralExpr(value: 1, range: .whatever),
                                   range: .whatever)
      let bDecl = VariableDeclStmt(variable: SourceVariable(name: "b", disambiguationIndex: 1, type: .int),
                                   expr: IntegerLiteralExpr(value: 2, range: .whatever),
                                   range: .whatever)
      let addition = BinaryOperatorExpr(lhs: VariableReferenceExpr(variable: .unresolved(name: "a"), range: .whatever),
                                        operator: .plus,
                                        rhs: VariableReferenceExpr(variable: .unresolved(name: "b"), range: .whatever),
                                        range: .whatever)
      let cDecl = VariableDeclStmt(variable: SourceVariable(name: "c", disambiguationIndex: 1, type: .int),
                                   expr: addition,
                                   range: .whatever)
      let observeCondition = BinaryOperatorExpr(lhs: IntegerLiteralExpr(value: 0, range: .whatever),
                                                operator: .lessThan,
                                                rhs: VariableReferenceExpr(variable: .unresolved(name: "c"), range: .whatever),
                                                range: .whatever)
      let observeStmt = ObserveStmt(condition: ParenExpr(subExpr: observeCondition, range: .whatever),
                                    range: .whatever)

      let expected = TopLevelCodeStmt(stmts: [aDecl, bDecl, cDecl, observeStmt], range: .whatever)

      XCTAssertEqualASTIgnoringRanges(ast, expected)
    }())
  }
  
  func testParseBoolConstant() {
    XCTAssertNoThrow(try {
      let parser = Parser.init(sourceCode: """
      bool a = true
      """)
      let ast = try parser.parseFile()
      
      let boolLiteralExpr = BoolLiteralExpr(value: true, range: .whatever)
      
      let decl = VariableDeclStmt(variable: SourceVariable(name: "a", disambiguationIndex: 1, type: .bool),
                                   expr: boolLiteralExpr,
                                   range: .whatever)
      
      let expected = TopLevelCodeStmt(stmts: [decl], range: .whatever)
      
      XCTAssertEqualASTIgnoringRanges(ast, expected)
    }())
  }
  
  func testParseIfElseStmt() {
    XCTAssertNoThrow(try {
      let parser = Parser.init(sourceCode: """
        int x = 1
        if true {
          x = 2
        } else {
          x = 3
        }
        """)
      let ast = try parser.parseFile()
      
      let xDecl = VariableDeclStmt(variable: SourceVariable(name: "x", disambiguationIndex: 1, type: .int),
                                   expr: IntegerLiteralExpr(value: 1, range: .whatever),
                                   range: .whatever)
      
      let ifBody = CodeBlockStmt(body: [
        AssignStmt(variable: .unresolved(name: "x"), expr: IntegerLiteralExpr(value: 2, range: .whatever), range: .whatever)
      ], range: .whatever)
      
      let elseBody = CodeBlockStmt(body: [
        AssignStmt(variable: .unresolved(name: "x"), expr: IntegerLiteralExpr(value: 3, range: .whatever), range: .whatever)
      ], range: .whatever)
      
      let ifStmt = IfStmt(
        condition: BoolLiteralExpr(value: true, range: .whatever),
        ifBody: ifBody,
        elseBody: elseBody,
        range: .whatever
      )
      
      let expected = TopLevelCodeStmt(stmts: [xDecl, ifStmt], range: .whatever)
      
      XCTAssertEqualASTIgnoringRanges(ast, expected)
    }())
  }
}
