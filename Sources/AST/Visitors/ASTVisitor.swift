/// A visitor that can walk an AST.
/// It can have two different return types for the different node types: `Stmt` and `Expr`.
public protocol ASTVisitor {
  
  /// The type returned when visiting `Expr` nodes
  associatedtype ExprReturnType
  
  /// The type returned when visiting `Stmt` nodes
  associatedtype StmtReturnType
  
  func visit(_ expr: BinaryOperatorExpr) -> ExprReturnType
  func visit(_ expr: IntegerLiteralExpr) -> ExprReturnType
  func visit(_ expr: FloatLiteralExpr) -> ExprReturnType
  func visit(_ expr: BoolLiteralExpr) -> ExprReturnType
  func visit(_ expr: VariableReferenceExpr) -> ExprReturnType
  func visit(_ expr: ParenExpr) -> ExprReturnType
  func visit(_ stmt: VariableDeclStmt) -> StmtReturnType
  func visit(_ stmt: AssignStmt) -> StmtReturnType
  func visit(_ stmt: ObserveStmt) -> StmtReturnType
  func visit(_ stmt: CodeBlockStmt) -> StmtReturnType
  func visit(_ stmt: IfStmt) -> StmtReturnType
  func visit(_ stmt: ProbStmt) -> StmtReturnType
  func visit(_ stmt: WhileStmt) -> StmtReturnType
}
