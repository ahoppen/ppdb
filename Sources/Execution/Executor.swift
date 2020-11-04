import AST
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
  public static func execute(stmt: Stmt, numSamples: Int) -> [Sample] {
    let samples = Array(repeating: Sample.empty, count: numSamples)
    return Executor.execute(stmt: stmt, samples: samples)
  }
  
  private static func execute(stmt: Stmt, samples: [Sample]) -> [Sample] {
    switch stmt {
    case let stmt as VariableDeclStmt:
      return samples.map({ sample in
        let value = sample.evaluate(expr: stmt.expr)
        return sample.assigning(variable: stmt.variable, value: value)
      })
    case let stmt as AssignStmt:
      guard case .resolved(let variable) = stmt.variable else {
        fatalError("AST must be resolved to be executed")
      }
      return samples.map({ sample in
        let value = sample.evaluate(expr: stmt.expr)
        return sample.assigning(variable: variable, value: value)
      })
    case let stmt as ObserveStmt:
      return samples.filter { sample in
        return sample.evaluate(expr: stmt.condition).bool!
      }
    case let stmt as CodeBlockStmt:
      var samples = samples
      for subStmt in stmt.body {
        samples = Executor.execute(stmt: subStmt, samples: samples)
      }
      return samples
    case let stmt as TopLevelCodeStmt:
      var samples = samples
      for subStmt in stmt.stmts {
        samples = Executor.execute(stmt: subStmt, samples: samples)
      }
      return samples
    case let stmt as IfStmt:
      let (trueSamples, falseSamples) = samples.partition(by: { $0.evaluate(expr: stmt.condition).bool! })
      let trueBranchSamplesAfterStmt = Executor.execute(stmt: stmt.ifBody, samples: trueSamples)
      let falseBranchSamplesAfterStmt: [Sample]
      if let elseBody = stmt.elseBody {
        falseBranchSamplesAfterStmt = Executor.execute(stmt: elseBody, samples: falseSamples)
      } else {
        falseBranchSamplesAfterStmt = falseSamples
      }
      return trueBranchSamplesAfterStmt + falseBranchSamplesAfterStmt
    case let stmt as ProbStmt:
      let (trueSamples, falseSamples) = samples.partition(by: { sample in
        let probability = sample.evaluate(expr: stmt.condition).float!
        return Double.random(in: 0..<1) < probability
      })
      let trueBranchSamplesAfterStmt = Executor.execute(stmt: stmt.ifBody, samples: trueSamples)
      let falseBranchSamplesAfterStmt: [Sample]
      if let elseBody = stmt.elseBody {
        falseBranchSamplesAfterStmt = Executor.execute(stmt: elseBody, samples: falseSamples)
      } else {
        falseBranchSamplesAfterStmt = falseSamples
      }
      return trueBranchSamplesAfterStmt + falseBranchSamplesAfterStmt
    case let stmt as WhileStmt:
      var liveSamples = samples
      var deadSamples: [Sample] = []
      repeat {
        let (trueSamples, falseSamples) = liveSamples.partition(by: { $0.evaluate(expr: stmt.condition).bool! })
        deadSamples += falseSamples
        liveSamples = trueSamples
        liveSamples = Executor.execute(stmt: stmt.body, samples: liveSamples)
      } while !liveSamples.isEmpty
      return deadSamples
    default:
      fatalError("Unknown Stmt type")
    }
  }
}
