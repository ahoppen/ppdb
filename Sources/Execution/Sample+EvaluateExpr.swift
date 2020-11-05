import AST
import ExecutionHistory

internal extension Sample {
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
