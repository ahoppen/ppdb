import AST
import TestUtils
import XCTest

class ASTDebugDescriptionTests: XCTestCase {
  func testDebugDescription() {
    // AST for the following source code:
    // while 1 < x {
    //   x = x - 1
    // }
    
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
    
    XCTAssertEqual(whileStmt.debugDescription, """
      ▽ WhileStmt
        ▽ Condition
          ▽ BinaryOperatorExpr(lessThan)
            ▷ IntegerLiteralExpr(1)
            ▷ VariableReferenceExpr(x (unresolved))
        ▽ CodeBlockStmt
          ▽ AssignStmt(name: x (unresolved))
            ▽ BinaryOperatorExpr(minus)
              ▷ VariableReferenceExpr(x (unresolved))
              ▷ IntegerLiteralExpr(1)
      """)
  }
}
