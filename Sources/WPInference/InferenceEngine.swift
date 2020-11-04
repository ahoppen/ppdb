import AST

public enum InferenceEngine {
  public static func infer(stmt: Stmt, f: Term) -> InferenceResult {
    return infer(stmt: stmt, previousResult: .initial(f: f))
  }
  
  internal static func infer(stmt: Stmt, previousResult: InferenceResult) -> InferenceResult {
    switch stmt {
    case let stmt as VariableDeclStmt:
      return previousResult.transformAllComponents(transformation: {
        $0.replacing(variable: stmt.variable, with: stmt.expr.term) ?? $0
      })
    case let stmt as AssignStmt:
      return previousResult.transformAllComponents(transformation: {
        $0.replacing(variable: stmt.variable.resolved!, with: stmt.expr.term) ?? $0
      })
    case let stmt as ObserveStmt:
      return previousResult.transformAllComponents(transformation: {
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
      return .combining(
        lhsMultiplier: .iverson(condition),
        lhs: ifInferenceResult,
        rhsMultiplier: Term.iverson(Term.not(condition).simplified).simplified,
        rhs: elseInferenceResult
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
      return .combining(
        lhsMultiplier: condition,
        lhs: ifInferenceResult,
        rhsMultiplier: (.number(1) - condition),
        rhs: elseInferenceResult
      )
    case let stmt as WhileStmt:
      let loopIterationBound = 10 // FIXME: Dynamic loop iteration bounds
      var intermediateResult = previousResult.transform(wpTransformation: {
        Term.iverson(Term.not(stmt.condition.term).simplified).simplified * $0
      }, wlpTransformation: {
        Term.iverson(stmt.condition.term).simplified + Term.iverson(Term.not(stmt.condition.term).simplified).simplified * $0
      })
      let condition = stmt.condition.term
      for _ in 0..<loopIterationBound {
        let bodyInferenceResult = infer(stmt: stmt.body, previousResult: intermediateResult)
        intermediateResult = .combining(
          lhsMultiplier: Term.iverson(condition).simplified,
          lhs: bodyInferenceResult,
          rhsMultiplier: Term.iverson(Term.not(condition).simplified).simplified,
          rhs: intermediateResult
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
