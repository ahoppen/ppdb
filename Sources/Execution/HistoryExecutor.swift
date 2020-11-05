import AST
import ExecutionHistory

public enum HistoryExecutor {
  public static func execute(history: ExecutionHistory, ast: TopLevelCodeStmt, numSamples: Int) -> [Sample] {
    return self.execute(history: history.augmented(with: ast), samples: Array(repeating: Sample.empty, count: numSamples))
  }
  
  public static func execute(history: AugmentedExecutionHistory, numSamples: Int) -> [Sample] {
    return self.execute(history: history, samples: Array(repeating: Sample.empty, count: numSamples))
  }
  
  private static func execute(history: AugmentedExecutionHistory, samples: [Sample]) -> [Sample] {
    var samples = samples
    for (debuggerCommand, stmt) in history.history {
      switch (debuggerCommand, stmt) {
      case (.stepOver, _):
        samples = Executor.execute(stmt: stmt, samples: samples, executionHistory: []).samples
      case (.stepIntoTrue, let stmt as IfStmt):
        samples = samples.filter({ sample in
          sample.evaluate(expr: stmt.condition).bool!
        })
      case (.stepIntoTrue, let stmt as ProbStmt):
        samples = samples.filter({ sample in
          let probability = sample.evaluate(expr: stmt.condition).float!
          return Double.random(in: 0..<1) < probability
        })
      case (.stepIntoTrue, let stmt as WhileStmt):
        samples = samples.filter({ sample in
          sample.evaluate(expr: stmt.condition).bool!
        })
      case (.stepIntoTrue, _):
        samples = Executor.execute(stmt: stmt, samples: samples, executionHistory: []).samples
        
      case (.stepIntoFalse, let stmt as IfStmt):
        samples = samples.filter({ sample in
          !sample.evaluate(expr: stmt.condition).bool!
        })
      case (.stepIntoFalse, let stmt as ProbStmt):
        samples = samples.filter({ sample in
          let probability = sample.evaluate(expr: stmt.condition).float!
          return !(Double.random(in: 0..<1) < probability)
        })
      case (.stepIntoFalse, let stmt as WhileStmt):
        samples = samples.filter({ sample in
          !sample.evaluate(expr: stmt.condition).bool!
        })
      case (.stepIntoFalse, _):
        samples = Executor.execute(stmt: stmt, samples: samples, executionHistory: []).samples
      }
    }
    return samples
  }
}
