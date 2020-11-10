public struct InferenceResult: Equatable {
  public let wpf: Term
  public let woip1: Term
  public let wlp1: Term
  public let wlp0: Term
  
  public init(wpf: Term, woip1: Term, wlp1: Term, wlp0: Term) {
    self.wpf = wpf
    self.woip1 = woip1
    self.wlp1 = wlp1
    self.wlp0 = wlp0
  }
  
  public static func initial(f: Term) -> InferenceResult {
    return InferenceResult(wpf: f, woip1: .number(1), wlp1: .number(1), wlp0: .number(0))
  }
  
  public static func combining(lhsMultiplier: Term, lhs: InferenceResult, rhsMultiplier: Term, rhs: InferenceResult) -> InferenceResult {
    return InferenceResult(
      wpf: lhsMultiplier * lhs.wpf + rhsMultiplier * rhs.wpf,
      woip1: lhsMultiplier * lhs.woip1 + rhsMultiplier * rhs.woip1,
      wlp1: lhsMultiplier * lhs.wlp1 + rhsMultiplier * rhs.wlp1,
      wlp0: lhsMultiplier * lhs.wlp0 + rhsMultiplier * rhs.wlp0
    )
  }
  
  internal func transformAllComponents(transformation: (Term) -> Term) -> InferenceResult {
    return InferenceResult(
      wpf: transformation(wpf),
      woip1: transformation(woip1),
      wlp1: transformation(wlp1),
      wlp0: transformation(wlp0)
    )
  }
  
  internal func transform(wpTransformation: (Term) -> Term, woipTransformation: (Term) -> Term, wlpTransformation: (Term) -> Term) -> InferenceResult {
    return InferenceResult(
      wpf: wpTransformation(wpf),
      woip1: woipTransformation(woip1),
      wlp1: wlpTransformation(wlp1),
      wlp0: wlpTransformation(wlp0)
    )
  }
}
