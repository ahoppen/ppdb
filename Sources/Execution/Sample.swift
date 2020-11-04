import AST

/// A single sample during probabilistic execution of a program
public struct Sample {
  /// The variables and their values.
  public let values: [SourceVariable: VariableValue]
  
  /// An empty sample without any values.
  public static var empty = Sample(values: [:])
  
  private init(values: [SourceVariable: VariableValue]) {
    self.values = values
  }
  
  /// Return a new sample in which the given `variable` has been assigned the given `value`.
  func assigning(variable: SourceVariable, value: VariableValue) -> Sample {
    return Sample(values: values.assiging(key: variable, value: value))
  }
}
