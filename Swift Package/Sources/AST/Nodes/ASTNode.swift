public protocol ASTNode: CustomDebugStringConvertible {
  /// The range in the source code that represents this AST node
  var range: SourceRange { get }
  
  /// Check if this AST node is equal to the `other` node while not comparing ranges.
  /// For testing purposes.
  func equalsIgnoringRange(other: ASTNode) -> Bool
  
  func accept<VisitorType: ASTRewriter>(_ visitor: VisitorType) throws -> Self
}

/// If a `ASTVisitor` or `ASTVerifier` returns the same type for expressions and statements, we can accept it on the generic `ASTNode` level and dispatch to the `Expr` or `Stmt` implementation.
public extension ASTNode {
  func accept<VisitorType: ASTVisitor>(_ visitor: VisitorType) -> VisitorType.ExprReturnType where VisitorType.ExprReturnType == VisitorType.StmtReturnType {
    if let expr = self as? Expr {
      return expr.accept(visitor)
    } else if let stmt = self as? Stmt {
      return stmt.accept(visitor)
    } else {
      fatalError("AST node is neither expression nor statement")
    }
  }
  
  func accept<VisitorType: ASTVerifier>(_ visitor: VisitorType) throws -> VisitorType.ExprReturnType where VisitorType.ExprReturnType == VisitorType.StmtReturnType {
    if let expr = self as? Expr {
      return try expr.accept(visitor)
    } else if let stmt = self as? Stmt {
      return try stmt.accept(visitor)
    } else {
      fatalError("AST node is neither expression nor statement")
    }
  }
}

public extension ASTNode {
  var debugDescription: String {
    return ASTDebugDescriptionGenerator().debugDescription(for: self)
  }
}
