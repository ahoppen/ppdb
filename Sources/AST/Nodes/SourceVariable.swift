/// A variable in the source code.
/// Until variable resolving, variable references only have a name and use the `UnresolvedVariable` type.
public struct SourceVariable: Hashable, CustomDebugStringConvertible {
  /// The name of the variable, as it is named in the source code
  public let name: String
  
  /// If a variable with this name is declared multiple times in the source code (e.g. because of shadowing), the two source variables are represented by two `Variable` structs that have different `disambiguationIndex`es
  public let disambiguationIndex: Int
  
  /// The type of the variable in the program
  public let type: Type
  
  public init(name: String, disambiguationIndex: Int, type: Type) {
    self.name = name
    self.disambiguationIndex = disambiguationIndex
    self.type = type
  }
  
  public var debugDescription: String {
    return "\(name) (\(type))"
  }
}

/// A variable that might not have been resolved yet. That is, we only know the name so far and haven't figured out which declaration it points to.
/// Once the variable has been resolved, the `resolved` case is being used.
public enum UnresolvedVariable: CustomDebugStringConvertible {
  /// We haven't resolved the variable yet, we only know its name
  case unresolved(name: String)
  /// The variable has been resolved
  case resolved(SourceVariable)
  
  public var resolved: SourceVariable? {
    switch self {
    case .resolved(let variable):
      return variable
    default:
      return nil
    }
  }
  
  public var debugDescription: String {
    switch self {
    case .unresolved(name: let name):
      return "\(name) (unresolved)"
    case .resolved(variable: let variable):
      return variable.debugDescription
    }
  }
  
  /// Check if two `UnresolvedVariables` have the same state (resolved/unresolved) and the same name.
  /// Only for testing purposes.
  public func hasSameName(as other: UnresolvedVariable) -> Bool {
    switch (self, other) {
    case (.unresolved(let lhsName), .unresolved(name: let rhsName)):
      return lhsName == rhsName
    case (.resolved, .unresolved):
      return false
    case (.unresolved, .resolved):
      return false
    case (.resolved(variable: let lhsVar), .resolved(variable: let rhsVar)):
      return lhsVar.name == rhsVar.name
    }
  }
}
