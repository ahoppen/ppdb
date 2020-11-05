/// The value a `SourceVariable` can take.
public enum VariableValue: Hashable, CustomStringConvertible {
  case integer(Int)
  case float(Double)
  case bool(Bool)
  
  /// If the value is of type `integer` return the value, else return `nil`.
  public var integer: Int? {
    switch self {
    case .integer(let value):
      return value
    default:
      return nil
    }
  }
  
  /// If the value is of type `float` return the value, else return `nil`.
  public var float: Double? {
    switch self {
    case .float(let value):
      return value
    default:
      return nil
    }
  }
  
  /// If the value is of type `bool` return the value, else return `nil`.
  public var bool: Bool? {
    switch self {
    case .bool(let value):
      return value
    default:
      return nil
    }
  }
  
  public var description: String {
    switch self {
    case .integer(let value):
      return value.description
    case .float(let value):
      return value.description
    case .bool(let value):
      return value.description
    }
  }
}
