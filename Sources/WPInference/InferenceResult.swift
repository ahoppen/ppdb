public struct InferenceResult: Equatable {
  public let wpf: Term
  public let wp1: Term
  public let wlp1: Term
  public let wlp0: Term
  
  public init(wpf: Term, wp1: Term, wlp1: Term, wlp0: Term) {
    self.wpf = wpf
    self.wp1 = wp1
    self.wlp1 = wlp1
    self.wlp0 = wlp0
  }
  
  public static func initial(f: Term) -> InferenceResult {
    return InferenceResult(wpf: f, wp1: .number(1), wlp1: .number(1), wlp0: .number(0))
  }
  
  public static func combining(lhsMultiplier: Term, lhs: InferenceResult, rhsMultiplier: Term, rhs: InferenceResult) -> InferenceResult {
    return InferenceResult(
      wpf: lhsMultiplier * lhs.wpf + rhsMultiplier * rhs.wpf,
      wp1: lhsMultiplier * lhs.wp1 + rhsMultiplier * rhs.wp1,
      wlp1: lhsMultiplier * lhs.wlp1 + rhsMultiplier * rhs.wlp1,
      wlp0: lhsMultiplier * lhs.wlp0 + rhsMultiplier * rhs.wlp0
    )
  }
  
  internal func transformAllComponents(transformation: (Term) -> Term) -> InferenceResult {
    return InferenceResult(
      wpf: transformation(wpf),
      wp1: transformation(wp1),
      wlp1: transformation(wlp1),
      wlp0: transformation(wlp0)
    )
  }
  
  internal func transform(wpTransformation: (Term) -> Term, wlpTransformation: (Term) -> Term) -> InferenceResult {
    return InferenceResult(
      wpf: wpTransformation(wpf),
      wp1: wpTransformation(wp1),
      wlp1: wlpTransformation(wlp1),
      wlp0: wlpTransformation(wlp0)
    )
  }
}
