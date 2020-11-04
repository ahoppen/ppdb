public struct InferenceResult: Equatable {
  public let wpf: Term
  
  public init(wpf: Term) {
    self.wpf = wpf
  }
  
  internal func transform(transformation: (Term) -> Term) -> InferenceResult {
    return InferenceResult(
      wpf: transformation(wpf)
    )
  }
}
