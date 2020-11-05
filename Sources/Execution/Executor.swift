import AST
import ExecutionHistory
import Utils

fileprivate extension Sample {
  /// Evaluate the given `expr` in this sample and return the value computed by it.
  /// If `expr` contains a `discrete` expresssion, the result does not have to be deterministic.
  func evaluate(expr: Expr) -> VariableValue {
    switch expr {
    case let expr as BinaryOperatorExpr:
      let lhsValue = self.evaluate(expr: expr.lhs)
      let rhsValue = self.evaluate(expr: expr.rhs)
      switch expr.operator {
      case .plus:
        return .integer(lhsValue.integer! + rhsValue.integer!)
      case .minus:
        return .integer(lhsValue.integer! - rhsValue.integer!)
      case .equal:
        switch (lhsValue, rhsValue) {
        case (.integer(let lhsValue), .integer(let rhsValue)):
          return .bool(lhsValue == rhsValue)
        case (.bool(let lhsValue), .bool(let rhsValue)):
          return .bool(lhsValue == rhsValue)
        default:
          fatalError("Both sides of '==' need to be of the same type")
        }
      case .lessThan:
        return .bool(lhsValue.integer! < rhsValue.integer!)
      }
    case let expr as IntegerLiteralExpr:
      return .integer(expr.value)
    case let expr as FloatLiteralExpr:
      return .float(expr.value)
    case let expr as BoolLiteralExpr:
      return .bool(expr.value)
    case let expr as VariableReferenceExpr:
      return values[expr.variable.resolved!]!
    case let expr as ParenExpr:
      return self.evaluate(expr: expr.subExpr)
    default:
      fatalError("Unknown Expr type")
    }
  }
}

public class Executor {
  public static func execute(stmt: Stmt, numSamples: Int) -> (samples: [Sample], loopIterationBounds: LoopIterationBounds) {
    let samples = Array(repeating: Sample.empty, count: numSamples)
    return Executor.execute(stmt: stmt, samples: samples)
  }
  
  private static func execute(stmt: Stmt, samples: [Sample]) -> (samples: [Sample], loopIterationBounds: LoopIterationBounds) {
    switch stmt {
    case let stmt as VariableDeclStmt:
      let newSamples = samples.map({ (sample) -> Sample in
        let value = sample.evaluate(expr: stmt.expr)
        return sample.assigning(variable: stmt.variable, value: value)
      })
      return (samples: newSamples, loopIterationBounds: .empty)
    case let stmt as AssignStmt:
      guard case .resolved(let variable) = stmt.variable else {
        fatalError("AST must be resolved to be executed")
      }
      let newSamples = samples.map({ (sample) -> Sample in
        let value = sample.evaluate(expr: stmt.expr)
        return sample.assigning(variable: variable, value: value)
      })
      return (samples: newSamples, loopIterationBounds: .empty)
    case let stmt as ObserveStmt:
      let newSamples = samples.filter { sample in
        return sample.evaluate(expr: stmt.condition).bool!
      }
      return (samples: newSamples, loopIterationBounds: .empty)
    case let stmt as CodeBlockStmt:
      var newSamples = samples
      var loopIterationBounds = LoopIterationBounds.empty
      for subStmt in stmt.body {
        let executionResult = Executor.execute(stmt: subStmt, samples: newSamples)
        newSamples = executionResult.samples
        loopIterationBounds = .merging(loopIterationBounds, executionResult.loopIterationBounds)
      }
      return (samples: newSamples, loopIterationBounds: loopIterationBounds)
    case let stmt as TopLevelCodeStmt:
      var newSamples = samples
      var loopIterationBounds = LoopIterationBounds.empty
      for subStmt in stmt.stmts {
        let executionResult = Executor.execute(stmt: subStmt, samples: newSamples)
        newSamples = executionResult.samples
        loopIterationBounds = LoopIterationBounds.merging(loopIterationBounds, executionResult.loopIterationBounds)
      }
      return (samples: newSamples, loopIterationBounds: loopIterationBounds)
    case let stmt as IfStmt:
      let (trueSamples, falseSamples) = samples.partition(by: { $0.evaluate(expr: stmt.condition).bool! })
      let trueBranchExecutionResult = Executor.execute(stmt: stmt.ifBody, samples: trueSamples)
      let trueBranchSamplesAfterStmt = trueBranchExecutionResult.samples
      var loopIterationBounds = trueBranchExecutionResult.loopIterationBounds
      
      let falseBranchSamplesAfterStmt: [Sample]
      if let elseBody = stmt.elseBody {
        let falseBranchExecutionResult = Executor.execute(stmt: elseBody, samples: falseSamples)
        falseBranchSamplesAfterStmt = falseBranchExecutionResult.samples
        loopIterationBounds = .merging(loopIterationBounds, falseBranchExecutionResult.loopIterationBounds)
      } else {
        falseBranchSamplesAfterStmt = falseSamples
      }
      return (
        samples: trueBranchSamplesAfterStmt + falseBranchSamplesAfterStmt,
        loopIterationBounds: loopIterationBounds
      )
    case let stmt as ProbStmt:
      let (trueSamples, falseSamples) = samples.partition(by: { sample in
        let probability = sample.evaluate(expr: stmt.condition).float!
        return Double.random(in: 0..<1) < probability
      })
      let trueBranchExecutionResult = Executor.execute(stmt: stmt.ifBody, samples: trueSamples)
      let trueBranchSamplesAfterStmt = trueBranchExecutionResult.samples
      var loopIterationBounds = trueBranchExecutionResult.loopIterationBounds
      
      let falseBranchSamplesAfterStmt: [Sample]
      if let elseBody = stmt.elseBody {
        let falseBranchExecutionResult = Executor.execute(stmt: elseBody, samples: falseSamples)
        falseBranchSamplesAfterStmt = falseBranchExecutionResult.samples
        loopIterationBounds = .merging(loopIterationBounds, falseBranchExecutionResult.loopIterationBounds)
      } else {
        falseBranchSamplesAfterStmt = falseSamples
      }
      return (
        samples: trueBranchSamplesAfterStmt + falseBranchSamplesAfterStmt,
        loopIterationBounds: loopIterationBounds
      )
    case let stmt as WhileStmt:
      var liveSamples = samples
      var deadSamples: [Sample] = []
      var loopIterationBounds: LoopIterationBounds = .empty
      
      // The first iteration of the executor performs the condition check and
      // only puts the samples that satisfy the condition in `liveSamples`.
      // Thus the only the second iteration of the below `repeat` loop evaluates
      // the first iteration of the `while` loop in the source code. Hence start
      // with an iteartion count of -1.
      var iterations = -1
      repeat {
        let (trueSamples, falseSamples) = liveSamples.partition(by: { $0.evaluate(expr: stmt.condition).bool! })
        deadSamples += falseSamples
        liveSamples = trueSamples
        let executionResult = Executor.execute(stmt: stmt.body, samples: liveSamples)
        liveSamples = executionResult.samples
        loopIterationBounds = .merging(loopIterationBounds, executionResult.loopIterationBounds)
        iterations += 1
      } while !liveSamples.isEmpty
      loopIterationBounds = loopIterationBounds.setting(loopId: stmt.loopId, to: iterations)
      return (samples: deadSamples, loopIterationBounds: loopIterationBounds)
    default:
      fatalError("Unknown Stmt type")
    }
  }
}
