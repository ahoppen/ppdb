import AST
import ExecutionHistory

public enum InferenceEngine {
  public static func infer(stmt: Stmt, loopIterationBounds: LoopIterationBounds, f: Term) -> InferenceResult {
    return infer(stmt: stmt, loopIterationBounds: loopIterationBounds, previousResult: .initial(f: f))
  }
  
  internal static func infer(stmt: Stmt, loopIterationBounds: LoopIterationBounds, previousResult: InferenceResult) -> InferenceResult {
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
      return previousResult.transform(wpTransformation: {
        return Term.iverson(stmt.condition.term) * $0
      }, woipTransformation: {
        return $0
      }, wlpTransformation: {
        return Term.iverson(stmt.condition.term) * $0
      })
    case let codeBlock as CodeBlockStmt:
      var intermediateResult = previousResult
      for stmt in codeBlock.body.reversed() {
        intermediateResult = infer(stmt: stmt, loopIterationBounds: loopIterationBounds, previousResult: intermediateResult)
      }
      return intermediateResult
    case let codeBlock as TopLevelCodeStmt:
      var intermediateResult = previousResult
      for stmt in codeBlock.stmts.reversed() {
        intermediateResult = infer(stmt: stmt, loopIterationBounds: loopIterationBounds, previousResult: intermediateResult)
      }
      return intermediateResult
    case let stmt as IfStmt:
      let ifInferenceResult = infer(stmt: stmt.ifBody, loopIterationBounds: loopIterationBounds, previousResult: previousResult)
      let elseInferenceResult: InferenceResult
      if let elseBody = stmt.elseBody {
        elseInferenceResult = infer(stmt: elseBody, loopIterationBounds: loopIterationBounds, previousResult: previousResult)
      } else {
        elseInferenceResult = previousResult
      }
      let condition = stmt.condition.term
      return .combining(
        lhsMultiplier: .iverson(condition),
        lhs: ifInferenceResult,
        rhsMultiplier: Term.iverson(Term.not(condition)),
        rhs: elseInferenceResult
      )
    case let stmt as ProbStmt:
      let ifInferenceResult = infer(stmt: stmt.ifBody, loopIterationBounds: loopIterationBounds, previousResult: previousResult)
      let elseInferenceResult: InferenceResult
      if let elseBody = stmt.elseBody {
        elseInferenceResult = infer(stmt: elseBody, loopIterationBounds: loopIterationBounds, previousResult: previousResult)
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
      guard let loopIterationBound = loopIterationBounds.bounds[stmt.loopId] else {
        fatalError("Missing a loop iteration bound for loop with ID \(stmt.loopId). Did you forget to specify one?")
      }
      var intermediateResult = previousResult.transform(wpTransformation: {
        Term.iverson(Term.not(stmt.condition.term)) * $0
      }, woipTransformation: {
        Term.iverson(Term.not(stmt.condition.term)) * $0
      },
      wlpTransformation: {
        Term.iverson(stmt.condition.term) + Term.iverson(Term.not(stmt.condition.term)) * $0
      })
      let condition = stmt.condition.term
      for _ in 0..<loopIterationBound {
        let bodyInferenceResult = infer(stmt: stmt.body, loopIterationBounds: loopIterationBounds, previousResult: intermediateResult)
        intermediateResult = .combining(
          lhsMultiplier: Term.iverson(condition),
          lhs: bodyInferenceResult,
          rhsMultiplier: Term.iverson(Term.not(condition)),
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
  public static func inferProbability(of variable: SourceVariable, being value: Term, loopIterationBounds: LoopIterationBounds, stmt: Stmt) -> InferenceResult {
    return infer(stmt: stmt, loopIterationBounds: loopIterationBounds, f: .iverson(.equal(lhs: .variable(variable), rhs: value)))
  }
}
