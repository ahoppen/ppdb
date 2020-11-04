import AST

public enum TypeCheckPipeline {
  public static func typeCheck(stmts: [Stmt]) throws -> [Stmt] {
    let stmts = try VariableResolver().resolveVariables(in: stmts)
    try TypeChecker().typeCheck(stmts: stmts)
    return stmts
  }
}
