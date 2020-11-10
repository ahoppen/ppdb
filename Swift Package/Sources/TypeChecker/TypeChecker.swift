import AST
import Parser

internal class TypeChecker: ASTVerifier {
  /// The type of an expression or `nil` if the verifier runs on a statement (which naturally doesn't have a type).
  typealias ExprReturnType = Type
  typealias StmtReturnType = Void
  
  func typeCheck(stmt: Stmt) throws {
    _ = try stmt.accept(self)
  }
  
  // MARK: - AST visitation
  
  func visit(_ expr: BinaryOperatorExpr) throws -> Type {
    let lhsType = try expr.lhs.accept(self)
    let rhsType = try expr.rhs.accept(self)
    switch (expr.operator, lhsType, rhsType) {
    case (.plus, .int, .int), (.minus, .int, .int):
      return .int
    case (.equal, .int, .int), (.lessThan, .int, .int):
      return .bool
    case (.plus, _, _), (.minus, _, _), (.equal, _, _), (.lessThan, _, _):
      throw CompilerError(range: expr.range, message: "Cannot apply '\(expr.operator)' to '\(lhsType)' and '\(rhsType)'")
    }
  }
  
  func visit(_ expr: IntegerLiteralExpr) throws -> Type {
    return .int
  }
  
  func visit(_ expr: FloatLiteralExpr) throws -> Type {
    return .float
  }
  
  func visit(_ expr: BoolLiteralExpr) throws -> Type {
    return .bool
  }
  
  func visit(_ expr: VariableReferenceExpr) throws -> Type {
    guard case .resolved(let variable) = expr.variable else {
      fatalError("Variables must be resolved in the AST before type checking")
    }
    return variable.type
  }
  
  func visit(_ expr: ParenExpr) throws -> Type {
    return try expr.subExpr.accept(self)
  }
  
  func visit(_ stmt: VariableDeclStmt) throws {
    let exprType = try stmt.expr.accept(self)
    if stmt.variable.type != exprType {
      throw CompilerError(range: stmt.range, message: "Cannot assign expression of type '\(exprType)' to variable of type '\(stmt.variable.type)'")
    }
  }
  
  func visit(_ stmt: AssignStmt) throws {
    guard case .resolved(let variable) = stmt.variable else {
      fatalError("Variables must be resolved in the AST before type checking")
    }
    let exprType = try stmt.expr.accept(self)
    if variable.type != exprType {
      throw CompilerError(range: stmt.range, message: "Cannot assign expression of type '\(exprType)' to variable of type '\(variable.type)'")
    }
  }
  
  func visit(_ stmt: ObserveStmt) throws {
    let conditionType = try stmt.condition.accept(self)
    if conditionType != .bool {
      throw CompilerError(range: stmt.range, message: "'observe' condition must to be boolean")
    }
  }
  
  func visit(_ codeBlock: CodeBlockStmt) throws {
    for stmt in codeBlock.body {
      _ = try stmt.accept(self)
    }
  }
  
  func visit(_ codeBlock: TopLevelCodeStmt) throws {
    for stmt in codeBlock.stmts {
      _ = try stmt.accept(self)
    }
  }
  
  func visit(_ stmt: IfStmt) throws {
    let conditionType = try stmt.condition.accept(self)
    if conditionType != .bool {
      throw CompilerError(range: stmt.range, message: "'if' condition must to be boolean")
    }
    try stmt.ifBody.accept(self)
    try stmt.elseBody?.accept(self)
  }
  
  func visit(_ stmt: ProbStmt) throws -> Void {
    let conditionType = try stmt.condition.accept(self)
    if conditionType != .float {
      throw CompilerError(range: stmt.range, message: "'prob' condition must to be of type float")
    }
    try stmt.ifBody.accept(self)
    try stmt.elseBody?.accept(self)
  }
  
  func visit(_ stmt: WhileStmt) throws {
    let conditionType = try stmt.condition.accept(self)
    if conditionType != .bool {
      throw CompilerError(range: stmt.range, message: "'while' condition must to be boolean")
    }
    try stmt.body.accept(self)
  }
}
