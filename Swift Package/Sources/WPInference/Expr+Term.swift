import AST

internal extension Expr {
  var term: Term {
    switch self {
    case let expr as BinaryOperatorExpr:
      let lhsTerm = expr.lhs.term
      let rhsTerm = expr.rhs.term
      switch expr.operator {
      case .plus:
        return lhsTerm + rhsTerm
      case .minus:
        return lhsTerm - rhsTerm
      case .equal:
        return .equal(lhs: lhsTerm, rhs: rhsTerm)
      case .lessThan:
        return .lessThan(lhs: lhsTerm, rhs: rhsTerm)
      }
    case let expr as IntegerLiteralExpr:
      return .number(Double(expr.value))
    case let expr as FloatLiteralExpr:
      return .number(expr.value)
    case let expr as BoolLiteralExpr:
      return .bool(expr.value)
    case let expr as VariableReferenceExpr:
      return .variable(expr.variable.resolved!)
    case let expr as ParenExpr:
      return expr.subExpr.term
    default:
      fatalError("Unknown Expr type")
    }
  }
}
