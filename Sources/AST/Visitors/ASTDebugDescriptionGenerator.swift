import Utils

/// `ASTVisitor` that is responsible for creating the `debugDescription` of AST nodes.
internal struct ASTDebugDescriptionGenerator: ASTVisitor {
  typealias ExprReturnType = String
  typealias StmtReturnType = String
  
  func visit(_ expr: BinaryOperatorExpr) -> String {
    return """
      ▽ BinaryOperatorExpr(\(expr.operator))
      \(expr.lhs.debugDescription.indented())
      \(expr.rhs.debugDescription.indented())
      """
  }
  
  func visit(_ expr: IntegerLiteralExpr) -> String {
    return "▷ IntegerLiteralExpr(\(expr.value))"
  }
  
  func visit(_ expr: FloatLiteralExpr) -> String {
    return "▷ FloatLiteralExpr(\(expr.value))"
  }
  
  func visit(_ expr: BoolLiteralExpr) -> String {
    return "▷ boolLiteralExpr(\(expr.value))"
  }
  
  func visit(_ expr: VariableReferenceExpr) -> String {
    return "▷ VariableReferenceExpr(\(expr.variable.debugDescription))"
  }
  
  func visit(_ expr: ParenExpr) -> String {
    return """
      ▽ ParenExpr
      \(expr.subExpr.debugDescription.indented())
      """
  }
  
  func visit(_ stmt: VariableDeclStmt) -> String {
    return """
      ▽ VariableDeclStmt(name: \(stmt.variable.name), type: \(stmt.variable.type))
      \(stmt.expr.debugDescription.indented())
      """
  }
  
  func visit(_ stmt: AssignStmt) -> String {
    return """
      ▽ AssignStmt(name: \(stmt.variable.debugDescription))
      \(stmt.expr.debugDescription.indented())
      """
  }
  
  func visit(_ stmt: ObserveStmt) -> String {
    return """
      ▽ ObserveStmt
      \(stmt.condition.debugDescription.indented())
      """
  }
  
  func visit(_ stmt: CodeBlockStmt) -> String {
    return """
      ▽ CodeBlockStmt
      \(stmt.body.map(\.debugDescription).joined(separator: "\n").indented())
      """
  }
  
  func visit(_ stmt: IfStmt) -> String {
    return """
      ▽ IfStmt
        ▽ Condition
      \(stmt.condition.debugDescription.indented(2))
        ▽ If-Body
      \(stmt.ifBody.debugDescription.indented(2))
        ▽ Else-Body
      \(stmt.elseBody.debugDescription.indented(2))
      """
  }
  
  func visit(_ stmt: ProbStmt) -> String {
    return """
      ▽ ProbStmt
        ▽ Condition
      \(stmt.condition.debugDescription.indented(2))
        ▽ If-Body
      \(stmt.ifBody.debugDescription.indented(2))
        ▽ Else-Body
      \(stmt.elseBody.debugDescription.indented(2))
      """
  }
  
  func visit(_ stmt: WhileStmt) -> String {
    return """
      ▽ WhileStmt
        ▽ Condition
      \(stmt.condition.debugDescription.indented(2))
      \(stmt.body.debugDescription.indented())
      """
  }
  
  func debugDescription(for node: ASTNode) -> String {
    return node.accept(self)
  }
}
