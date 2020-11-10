import AST
import Parser

/// A scope in which variables are declared.
/// Can be queried for variable declarations in itself or any of its parent scopes.
fileprivate class VariableScope {
  let outerScope: VariableScope?
  private var identifiers: [String: SourceVariable] = [:]
      
  init(outerScope: VariableScope?) {
    self.outerScope = outerScope
  }

  func declare(variable: SourceVariable) {
    assert(!isDeclared(name: variable.name), "Variable already declared")
    identifiers[variable.name] = variable
  }
  
  func isDeclared(name: String) -> Bool {
    return identifiers[name] != nil
  }
  
  func lookup(name: String) -> SourceVariable? {
    if let variable = identifiers[name] {
      return variable
    } else if let outerScope = outerScope {
      return outerScope.lookup(name: name)
    } else {
      return nil
    }
  }
}

/// Resolves variable references in a source file.
/// While doing it, checks that no variable is declared twice or used before being defined.
internal class VariableResolver: ASTRewriter {
  private var variableScope = VariableScope(outerScope: nil)
  
  public func resolveVariables(in stmts: Stmt) throws -> Stmt {
    return try stmts.accept(self)
  }
  
  // MARK: - Handle scopes
  
  private func pushScope() {
    variableScope = VariableScope(outerScope: variableScope)
  }
  
  private func popScope() {
    guard let outerScope = self.variableScope.outerScope else {
      fatalError("Cannot pop scope. Already on outer scope")
    }
    self.variableScope = outerScope
  }
  
  // MARK: - Visit nodes
  
  func visit(_ stmt: CodeBlockStmt) throws -> CodeBlockStmt {
    pushScope()
    defer { popScope() }
    
    return CodeBlockStmt(body: try stmt.body.map( { try $0.accept(self) }),
                         range: stmt.range)
  }
  
  func visit(_ stmt: VariableDeclStmt) throws -> VariableDeclStmt {
    guard !variableScope.isDeclared(name: stmt.variable.name) else {
      throw CompilerError(range: stmt.range, message: "Variable '\(stmt.variable.name)' is already declared.")
    }
    let resolvedExpr = try stmt.expr.accept(self)
    variableScope.declare(variable: stmt.variable)
    return VariableDeclStmt(variable: stmt.variable,
                            expr: resolvedExpr,
                            range: stmt.range)
  }
  
  func visit(_ stmt: AssignStmt) throws -> AssignStmt {
    guard case .unresolved(let name) = stmt.variable else {
      fatalError("Variable has already been resolved")
    }
    guard let variable = variableScope.lookup(name: name) else {
      throw CompilerError(range: stmt.range, message: "Variable '\(name)' has not been declared")
    }
    return AssignStmt(variable: .resolved(variable),
                      expr: try stmt.expr.accept(self),
                      range: stmt.range)
  }
  
  func visit(_ expr: VariableReferenceExpr) throws -> VariableReferenceExpr {
    guard case .unresolved(let name) = expr.variable else {
      fatalError("Variable has already been resolved")
    }
    guard let variable = variableScope.lookup(name: name) else {
      throw CompilerError(range: expr.range, message: "Variable '\(name)' has not been declared")
    }
    return VariableReferenceExpr(variable: .resolved(variable),
                          range: expr.range)
  }
}
