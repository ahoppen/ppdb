import AST
import ExecutionHistory

public enum HistoryInferenceEngine {
  public static func infer(history: ExecutionHistory, loopIterationBounds: LoopIterationBounds, ast: TopLevelCodeStmt, f: Term) throws -> InferenceResult {
    return infer(history: try history.augmented(with: ast), loopIterationBounds: loopIterationBounds, previousResult: .initial(f: f))
  }
  
  public static func infer(history: AugmentedExecutionHistory, loopIterationBounds: LoopIterationBounds, f: Term) -> InferenceResult {
    return infer(history: history, loopIterationBounds: loopIterationBounds, previousResult: .initial(f: f))
  }
  
  private static func infer(history: AugmentedExecutionHistory, loopIterationBounds: LoopIterationBounds, previousResult: InferenceResult) -> InferenceResult {
    var intermediateResult = previousResult
    for (debuggerCommand, stmt) in history.history.reversed() {
      switch (debuggerCommand, stmt) {
      case (.stepOver, _):
        intermediateResult = InferenceEngine.infer(stmt: stmt, loopIterationBounds: loopIterationBounds, previousResult: intermediateResult)
        
      case (.stepIntoTrue, let stmt as IfStmt):
        intermediateResult = intermediateResult.transform(wpTransformation: {
          return Term.iverson(stmt.condition.term) * $0
        },
        woipTransformation: {
          return $0
        }, wlpTransformation: {
          return Term.iverson(stmt.condition.term) * $0
        })
      case (.stepIntoTrue, let stmt as ProbStmt):
        intermediateResult = intermediateResult.transform(wpTransformation: {
          return stmt.condition.term * $0
        }, woipTransformation: {
          return $0
        }, wlpTransformation: {
          return stmt.condition.term * $0
        })
      case (.stepIntoTrue, let stmt as WhileStmt):
        intermediateResult = intermediateResult.transform(wpTransformation: {
          return Term.iverson(stmt.condition.term) * $0
        },
        woipTransformation: {
          return $0
        }, wlpTransformation: {
          return Term.iverson(stmt.condition.term) * $0
        })
      case (.stepIntoTrue, _):
        intermediateResult = InferenceEngine.infer(stmt: stmt, loopIterationBounds: loopIterationBounds, previousResult: intermediateResult)
        
      case (.stepIntoFalse, let stmt as IfStmt):
        intermediateResult = intermediateResult.transform(wpTransformation: {
          return Term.iverson(Term.not(stmt.condition.term)) * $0
        }, woipTransformation: {
          return $0
        }, wlpTransformation: {
          return Term.iverson(Term.not(stmt.condition.term)) * $0
        })
      case (.stepIntoFalse, let stmt as ProbStmt):
        intermediateResult = intermediateResult.transform(wpTransformation: {
          return (.number(1) - stmt.condition.term) * $0
        }, woipTransformation: {
          return $0
        }, wlpTransformation: {
          return (.number(1) - stmt.condition.term) * $0
        })
      case (.stepIntoFalse, let stmt as WhileStmt):
        intermediateResult = intermediateResult.transform(wpTransformation: {
          return Term.iverson(Term.not(stmt.condition.term)) * $0
        }, woipTransformation: {
          return $0
        }, wlpTransformation: {
          return Term.iverson(Term.not(stmt.condition.term)) * $0
        })
      case (.stepIntoFalse, _):
        intermediateResult = InferenceEngine.infer(stmt: stmt, loopIterationBounds: loopIterationBounds, previousResult: intermediateResult)
      }
    }
    return intermediateResult
  }
}
