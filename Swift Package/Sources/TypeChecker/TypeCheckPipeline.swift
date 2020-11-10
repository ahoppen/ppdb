import AST

public enum TypeCheckPipeline {
  public static func typeCheck(stmt: Stmt) throws -> Stmt {
    let stmt = try VariableResolver().resolveVariables(in: stmt)
    try TypeChecker().typeCheck(stmt: stmt)
    return stmt
  }
}
