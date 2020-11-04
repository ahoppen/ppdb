import AST

public enum InferenceEngine {
  public static func infer(stmt: Stmt, f: Term) -> InferenceResult {
    return infer(stmt: stmt, previousResult: InferenceResult(wpf: f))
  }
  
  internal static func infer(stmt: Stmt, previousResult: InferenceResult) -> InferenceResult {
    switch stmt {
    case let stmt as VariableDeclStmt:
      return previousResult.transform(transformation: {
        $0.replacing(variable: stmt.variable, with: stmt.expr.term) ?? $0
      })
    case let stmt as AssignStmt:
      return previousResult.transform(transformation: {
        $0.replacing(variable: stmt.variable.resolved!, with: stmt.expr.term) ?? $0
      })
    case let stmt as ObserveStmt:
      return previousResult.transform(transformation: {
        return Term.iverson(stmt.condition.term).simplified * $0
      })
    case let codeBlock as CodeBlockStmt:
      var intermediateResult = previousResult
      for stmt in codeBlock.body.reversed() {
        intermediateResult = infer(stmt: stmt, previousResult: intermediateResult)
      }
      return intermediateResult
    case let codeBlock as TopLevelCodeStmt:
      var intermediateResult = previousResult
      for stmt in codeBlock.stmts.reversed() {
        intermediateResult = infer(stmt: stmt, previousResult: intermediateResult)
      }
      return intermediateResult
    case let stmt as IfStmt:
      let ifInferenceResult = infer(stmt: stmt.ifBody, previousResult: previousResult)
      let elseInferenceResult: InferenceResult
      if let elseBody = stmt.elseBody {
        elseInferenceResult = infer(stmt: elseBody, previousResult: previousResult)
      } else {
        elseInferenceResult = previousResult
      }
      let condition = stmt.condition.term
      return InferenceResult(
        wpf: .iverson(condition) * ifInferenceResult.wpf + .iverson(.not(condition)) * elseInferenceResult.wpf
      )
    case let stmt as ProbStmt:
      let ifInferenceResult = infer(stmt: stmt.ifBody, previousResult: previousResult)
      let elseInferenceResult: InferenceResult
      if let elseBody = stmt.elseBody {
        elseInferenceResult = infer(stmt: elseBody, previousResult: previousResult)
      } else {
        elseInferenceResult = previousResult
      }
      let condition = stmt.condition.term
      return InferenceResult(
        wpf: condition * ifInferenceResult.wpf + (.number(1) - condition) * elseInferenceResult.wpf
      )
    case let stmt as WhileStmt:
      let loopIterationBound = 10 // FIXME: Dynamic loop iteration bounds
      var intermediateResult = InferenceResult(
        wpf: Term.iverson(Term.not(stmt.condition.term).simplified).simplified * previousResult.wpf
      )
      let condition = stmt.condition.term
      for _ in 0..<loopIterationBound {
        let bodyInferenceResult = infer(stmt: stmt.body, previousResult: intermediateResult)
        intermediateResult = InferenceResult(
          wpf: Term.iverson(condition).simplified * bodyInferenceResult.wpf + Term.iverson(Term.not(condition).simplified).simplified * intermediateResult.wpf
        )
      }
      return intermediateResult
    default:
      fatalError("Unknown Stmt type")
    }
  }
}

extension InferenceEngine {
  public static func inferProbability(of variable: SourceVariable, being value: Term, stmt: Stmt) -> InferenceResult {
    return infer(stmt: stmt, f: .iverson(.equal(lhs: .variable(variable), rhs: value)))
  }
}
