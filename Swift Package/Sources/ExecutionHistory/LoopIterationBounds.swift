import AST

public struct LoopIterationBounds: Equatable, ExpressibleByDictionaryLiteral {
  public let bounds: [LoopId: Int]
  
  public init(bounds: [LoopId: Int]) {
    self.bounds = bounds
  }
  
  public init(dictionaryLiteral elements: (LoopId, Int)...) {
    self.bounds = Dictionary(uniqueKeysWithValues: elements)
  }
  
  /// Merge two `LoopIterationBounds` by taking the maximum bound for each loop.
  public static func merging(_ lhs: LoopIterationBounds, _ rhs: LoopIterationBounds) -> LoopIterationBounds {
    return LoopIterationBounds(bounds: Dictionary.merged([lhs.bounds, rhs.bounds], uniquingKeysWith: {
      return max($0, $1)
    }))
  }
  
  public func setting(loopId: LoopId, to bound: Int) -> LoopIterationBounds {
    return .merging(self, LoopIterationBounds(bounds: [loopId: bound]))
  }
}
