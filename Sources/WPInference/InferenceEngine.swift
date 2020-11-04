import AST

public struct InferenceResult: Equatable {
  public let wpf: Term
  
  public init(wpf: Term) {
    self.wpf = wpf
  }
  
  fileprivate func transform(transformation: (Term) -> Term) -> InferenceResult {
    return InferenceResult(
      wpf: transformation(wpf)
    )
  }
}

fileprivate extension Expr {
  var Term: Term {
    switch self {
    case let expr as BinaryOperatorExpr:
      let lhsTerm = expr.lhs.Term
      let rhsTerm = expr.rhs.Term
      switch expr.operator {
      case .plus:
        return .add(lhs: lhsTerm, rhs: rhsTerm)
      case .minus:
        return .sub(lhs: lhsTerm, rhs: rhsTerm)
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
      return expr.subExpr.Term
    default:
      fatalError("Unknown Expr type")
    }
  }
}

public enum InferenceEngine {
  public static func infer(stmts: [Stmt], f: Term) -> InferenceResult {
    assert(!stmts.isEmpty)
    let codeBlockStmt = CodeBlockStmt(body: stmts, range: stmts.first!.range.lowerBound..<stmts.last!.range.upperBound)
    return infer(stmt: codeBlockStmt, f: f)
  }
  
  public static func infer(stmt: Stmt, f: Term) -> InferenceResult {
    return infer(stmt: stmt, previousResult: InferenceResult(wpf: f))
  }
  
  private static func infer(stmt: Stmt, previousResult: InferenceResult) -> InferenceResult {
    switch stmt {
    case let stmt as VariableDeclStmt:
      return previousResult.transform(transformation: {
        $0.replacing(variable: stmt.variable, with: stmt.expr.Term) ?? $0
      })
    case let stmt as AssignStmt:
      return previousResult.transform(transformation: {
        $0.replacing(variable: stmt.variable.resolved!, with: stmt.expr.Term) ?? $0
      })
    case let stmt as ObserveStmt:
      return previousResult.transform(transformation: {
        return .iverson(stmt.condition.Term) * $0
      })
    case let codeBlock as CodeBlockStmt:
      var intermediateResult = previousResult
      for stmt in codeBlock.body.reversed() {
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
      let condition = stmt.condition.Term
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
      let condition = stmt.condition.Term
      return InferenceResult(
        wpf: condition * ifInferenceResult.wpf + (.number(1) - condition) * elseInferenceResult.wpf
      )
    case let stmt as WhileStmt:
      let loopIterationBound = 10 // FIXME: Dynamic loop iteration bounds
      var intermediateResult = InferenceResult(
        wpf: Term.iverson(Term.not(stmt.condition.Term).simplified).simplified * previousResult.wpf
      )
      let condition = stmt.condition.Term
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
  public static func inferProbability(of variable: SourceVariable, being value: Term, stmts: [Stmt]) -> InferenceResult {
    return infer(stmts: stmts, f: .iverson(.equal(lhs: .variable(variable), rhs: value)))
  }
}
