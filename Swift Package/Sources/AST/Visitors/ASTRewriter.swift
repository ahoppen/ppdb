/// A type that takes an AST and rewrites it to a different AST while preserving node types.
/// By default all methods are implemented as a transformation that visits all children and creates a new node based on the rewritten children nodes.
public protocol ASTRewriter {
  func visit(_ expr: BinaryOperatorExpr) throws -> BinaryOperatorExpr
  func visit(_ expr: IntegerLiteralExpr) throws -> IntegerLiteralExpr
  func visit(_ expr: FloatLiteralExpr) throws -> FloatLiteralExpr
  func visit(_ expr: BoolLiteralExpr) throws -> BoolLiteralExpr
  func visit(_ expr: VariableReferenceExpr) throws -> VariableReferenceExpr
  func visit(_ expr: ParenExpr) throws -> ParenExpr
  func visit(_ stmt: VariableDeclStmt) throws -> VariableDeclStmt
  func visit(_ stmt: AssignStmt) throws -> AssignStmt
  func visit(_ stmt: ObserveStmt) throws -> ObserveStmt
  func visit(_ stmt: CodeBlockStmt) throws -> CodeBlockStmt
  func visit(_ stmt: TopLevelCodeStmt) throws -> TopLevelCodeStmt
  func visit(_ stmt: IfStmt) throws -> IfStmt
  func visit(_ stmt: ProbStmt) throws -> ProbStmt
  func visit(_ stmt: WhileStmt) throws -> WhileStmt
}

public extension ASTRewriter {
  func visit(_ expr: BinaryOperatorExpr) throws -> BinaryOperatorExpr {
    return BinaryOperatorExpr(lhs: try expr.lhs.accept(self),
                              operator: expr.operator,
                              rhs: try expr.rhs.accept(self),
                              range: expr.range)
  }
  
  func visit(_ expr: IntegerLiteralExpr) -> IntegerLiteralExpr {
    return expr
  }
  
  func visit(_ expr: FloatLiteralExpr) -> FloatLiteralExpr {
    return expr
  }
  
  func visit(_ expr: BoolLiteralExpr) -> BoolLiteralExpr {
    return expr
  }
  
  func visit(_ expr: VariableReferenceExpr) -> VariableReferenceExpr {
    return expr
  }
  
  func visit(_ expr: ParenExpr) throws -> ParenExpr {
    return ParenExpr(subExpr: try expr.subExpr.accept(self),
                     range: expr.range)
  }
  
  func visit(_ stmt: VariableDeclStmt) throws -> VariableDeclStmt {
    return VariableDeclStmt(variable: stmt.variable,
                            expr: try stmt.expr.accept(self),
                            range: stmt.range)
  }
  
  func visit(_ stmt: AssignStmt) throws -> AssignStmt {
    return AssignStmt(variable: stmt.variable,
                      expr: try stmt.expr.accept(self),
                      range: stmt.range)
  }
  
  func visit(_ stmt: ObserveStmt) throws -> ObserveStmt {
    return ObserveStmt(condition: try stmt.condition.accept(self),
                       range: stmt.range)
  }
  
  func visit(_ stmt: CodeBlockStmt) throws -> CodeBlockStmt {
    return CodeBlockStmt(body: try stmt.body.map( { try $0.accept(self) }),
                         range: stmt.range)
  }
  
  func visit(_ stmt: TopLevelCodeStmt) throws -> TopLevelCodeStmt {
    return TopLevelCodeStmt(stmts: try stmt.stmts.map( { try $0.accept(self) }),
                            range: stmt.range)
  }
  
  func visit(_ stmt: IfStmt) throws -> IfStmt {
    return IfStmt(condition: try stmt.condition.accept(self),
                  ifBody: try stmt.ifBody.accept(self),
                  elseBody: try stmt.elseBody?.accept(self),
                  range: stmt.range)
  }
  
  func visit(_ stmt: ProbStmt) throws -> ProbStmt {
    return ProbStmt(condition: try stmt.condition.accept(self),
                      ifBody: try stmt.ifBody.accept(self),
                      elseBody: try stmt.elseBody?.accept(self),
                      range: stmt.range)
  }
  
  func visit(_ stmt: WhileStmt) throws -> WhileStmt {
    return WhileStmt(condition: try stmt.condition.accept(self),
                     body: try stmt.body.accept(self),
                     loopId: stmt.loopId,
                     range: stmt.range)
  }
  
}
