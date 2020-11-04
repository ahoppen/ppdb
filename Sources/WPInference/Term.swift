import AST

public indirect enum Term: Equatable {
  case number(Double)
  case bool(Bool)
  case variable(SourceVariable)
  
  case not(Term)
  case iverson(Term)
  
  case add(lhs: Term, rhs: Term)
  case sub(lhs: Term, rhs: Term)
  case mul(lhs: Term, rhs: Term)
  case equal(lhs: Term, rhs: Term)
  case lessThan(lhs: Term, rhs: Term)
}

public extension Term {
  func replacing(variable: SourceVariable, with replacementTerm: Term) -> Term? {
    switch self {
    case .number, .bool:
      return nil
    case .variable(let myVariable):
      if variable == myVariable {
        return replacementTerm
      } else {
        return self
      }
    case .not(let wrappedTerm):
      if let replaced = wrappedTerm.replacing(variable: variable, with: replacementTerm) {
        return Term.not(replaced).simplified
      }
      return nil
    case .iverson(let wrappedTerm):
      if let replaced = wrappedTerm.replacing(variable: variable, with: replacementTerm) {
        return Term.iverson(replaced).simplified
      }
      return nil
    case .add(lhs: let lhs, rhs: let rhs):
      let lhsReplaced = lhs.replacing(variable: variable, with: replacementTerm)
      let rhsReplaced = rhs.replacing(variable: variable, with: replacementTerm)
      if lhsReplaced == nil && rhsReplaced == nil {
        return nil
      }
      return Term.add(lhs: lhsReplaced ?? lhs, rhs: rhsReplaced ?? rhs).simplified
    case .sub(lhs: let lhs, rhs: let rhs):
      let lhsReplaced = lhs.replacing(variable: variable, with: replacementTerm)
      let rhsReplaced = rhs.replacing(variable: variable, with: replacementTerm)
      if lhsReplaced == nil && rhsReplaced == nil {
        return nil
      }
      return Term.sub(lhs: lhsReplaced ?? lhs, rhs: rhsReplaced ?? rhs).simplified
    case .mul(lhs: let lhs, rhs: let rhs):
      let lhsReplaced = lhs.replacing(variable: variable, with: replacementTerm)
      let rhsReplaced = rhs.replacing(variable: variable, with: replacementTerm)
      if lhsReplaced == nil && rhsReplaced == nil {
        return nil
      }
      return Term.mul(lhs: lhsReplaced ?? lhs, rhs: rhsReplaced ?? rhs).simplified
    case .equal(lhs: let lhs, rhs: let rhs):
      let lhsReplaced = lhs.replacing(variable: variable, with: replacementTerm)
      let rhsReplaced = rhs.replacing(variable: variable, with: replacementTerm)
      if lhsReplaced == nil && rhsReplaced == nil {
        return nil
      }
      return Term.equal(lhs: lhsReplaced ?? lhs, rhs: rhsReplaced ?? rhs).simplified
    case .lessThan(lhs: let lhs, rhs: let rhs):
      let lhsReplaced = lhs.replacing(variable: variable, with: replacementTerm)
      let rhsReplaced = rhs.replacing(variable: variable, with: replacementTerm)
      if lhsReplaced == nil && rhsReplaced == nil {
        return nil
      }
      return Term.lessThan(lhs: lhsReplaced ?? lhs, rhs: rhsReplaced ?? rhs).simplified
    }
  }
}

public extension Term {
  var simplified: Term {
    switch self {
    case .number, .bool, .variable:
      return self
    case .not(let wrapped):
      switch wrapped {
      case .not(let doubleWrapped):
        return doubleWrapped
      case .bool(true):
        return .bool(false)
      case .bool(false):
        return .bool(true)
      default:
        return self
      }
    case .iverson(let wrapped):
      switch wrapped {
      case .bool(true):
        return .number(1)
      case .bool(false):
        return .number(0)
      default:
        return self
      }
    case .add(lhs: let lhs, rhs: let rhs):
      switch (lhs, rhs) {
      case (.number(let lhs), .number(let rhs)):
        return .number(lhs + rhs)
      default:
        return self
      }
    case .sub(lhs: let lhs, rhs: let rhs):
      switch (lhs, rhs) {
      case (.number(let lhs), .number(let rhs)):
        return .number(lhs - rhs)
      default:
        return self
      }
    case .mul(lhs: let lhs, rhs: let rhs):
      switch (lhs, rhs) {
      case (.number(let lhs), .number(let rhs)):
        return .number(lhs * rhs)
      case (.number(0), _):
        return .number(0)
      case (_, .number(0)):
        return .number(0)
      default:
        return self
      }
    case .equal(lhs: let lhs, rhs: let rhs):
      switch (lhs, rhs) {
      case (.number(let lhs), .number(let rhs)):
        return .bool(lhs == rhs)
      case (.bool(let lhs), .bool(let rhs)):
        return .bool(lhs == rhs)
      default:
        return self
      }
    case .lessThan(lhs: let lhs, rhs: let rhs):
      switch (lhs, rhs) {
      case (.number(let lhs), .number(let rhs)):
        return .bool(lhs < rhs)
      default:
        return self
      }
    }
  }
}

public extension Term {
  var treeDescription: String {
    switch self {
    case .number(let value):
      return "▷ \(value.description)"
    case .bool(let value):
      return "▷ \(value.description)"
    case .variable(let variable):
      return "▷ \(variable)"
    case .not(let term):
      return """
      ▽ Negated
      \(term.treeDescription.indented())
      """
    case .iverson(let term):
      return """
      ▽ Iverson
      \(term.treeDescription.indented())
      """
    case .add(lhs: let lhs, rhs: let rhs):
      return """
      ▽ +
      \(lhs.treeDescription.indented())
      \(rhs.treeDescription.indented())
      """
    case .sub(lhs: let lhs, rhs: let rhs):
      return """
      ▽ +
      \(lhs.treeDescription.indented())
      \(rhs.treeDescription.indented())
      """
    case .mul(lhs: let lhs, rhs: let rhs):
      return """
      ▽ +
      \(lhs.treeDescription.indented())
      \(rhs.treeDescription.indented())
      """
    case .equal(lhs: let lhs, rhs: let rhs):
      return """
      ▽ =
      \(lhs.treeDescription.indented())
      \(rhs.treeDescription.indented())
      """
    case .lessThan(lhs: let lhs, rhs: let rhs):
      return """
      ▽ <
      \(lhs.treeDescription.indented())
      \(rhs.treeDescription.indented())
      """
    }
  }
}

public func +(lhs: Term, rhs: Term) -> Term {
  return Term.add(lhs: lhs, rhs: rhs).simplified
}

public func -(lhs: Term, rhs: Term) -> Term {
  return Term.sub(lhs: lhs, rhs: rhs).simplified
}

public func *(lhs: Term, rhs: Term) -> Term {
  return Term.mul(lhs: lhs, rhs: rhs).simplified
}
