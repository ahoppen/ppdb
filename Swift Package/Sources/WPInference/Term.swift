import Foundation
import Utils
import AST

extension Array where Element == Term {
  internal func replacing(variable: SourceVariable, with replacementTerm: Term) -> [Term]? {
    var hasPerformedReplacement = false
    let replacedTerms = self.map({ (term) -> Term in
      if let replaced = term.replacing(variable: variable, with: replacementTerm) {
        hasPerformedReplacement = true
        return replaced
      } else {
        return term
      }
    })
    if hasPerformedReplacement {
      return replacedTerms
    } else {
      return nil
    }
  }
}

public indirect enum Term: Hashable, CustomStringConvertible {
  // MARK: Cases and constructors
  
  /// An IR variable that has not been replaced by a concrete value yet
  case variable(SourceVariable)
  
  /// A floating-Point literal
  case number(Double)
  
  /// A boolean literal
  case bool(Bool)
  
  /// Negate a boolean value
  case _not(Term)
  
  /// Convert a boolean value to an integer by mapping `false` to `0` and `true` to `1`.
  case _iverson(Term)
  
  /// Compare the two given terms. Returns a boolean value. The two terms must be of the same type to be considered equal
  case _equal(lhs: Term, rhs: Term)
  
  /// Compare if `lhs` is strictly less than `rhs` (`lhs < rhs`)
  case _lessThan(lhs: Term, rhs: Term)
  
  /// Add all the given `terms`. An empty sum has the value `0`.
  case _additionList(AdditionList)
  
  /// Subtract `rhs` from `lhs`
  case _sub(lhs: Term, rhs: Term)
  
  /// Multiply `terms`.
  case _mul(terms: [Term])
  
  /// Divide `term` by `divisors`
  /// The result of `0 / 0` is undefined. It can be `0`, `nan` or something completely different.
  case _div(term: Term, divisors: [Term])
  
  /// Divide `term` by `divisors` with the additional semantics that `0 / 0` is well-defined as `0`.
  case _zeroDiv(term: Term, divisors: [Term])
  
  public static func not(_ wrapped: Term) -> Term {
    return _not(wrapped).simplified(recursively: false)
  }
  
  public static func iverson(_ wrapped: Term) -> Term {
    return _iverson(wrapped).simplified(recursively: false)
  }
  
  public static func equal(lhs: Term, rhs: Term) -> Term {
    return _equal(lhs: lhs, rhs: rhs).simplified(recursively: false)
  }
  
  public static func lessThan(lhs: Term, rhs: Term) -> Term {
    return _lessThan(lhs: lhs, rhs: rhs).simplified(recursively: false)
  }
  
  public static func add(terms: [Term]) -> Term {
    return _additionList(AdditionList(terms.map({ TermAdditionListEntry(factor: 1, conditions: [], term: $0) }))).simplified(recursively: false)
  }
  
  public static func sub(lhs: Term, rhs: Term) -> Term {
    return _sub(lhs: lhs, rhs: rhs).simplified(recursively: false)
  }
  
  public static func mul(terms: [Term]) -> Term {
    return _mul(terms: terms).simplified(recursively: false)
  }
  
  public static func div(lhs: Term, rhs: Term) -> Term {
    return _div(term: lhs, divisors: [rhs]).simplified(recursively: false)
  }
  
  public static func zeroDiv(lhs: Term, rhs: Term) -> Term {
    return _zeroDiv(term: lhs, divisors: [rhs]).simplified(recursively: false)
  }
  
  // MARK: Descriptions
  
  
  public var description: String {
    switch self {
    case .variable(let variable):
      return variable.description
    case .number(let value):
      return value.description
    case .bool(let value):
      return value.description
    case ._not(let term):
      return "!(\(term))"
    case ._iverson(let term):
      return "[\(term)]"
    case ._equal(lhs: let lhs, rhs: let rhs):
      return "(\(lhs.description) = \(rhs.description))"
    case ._lessThan(lhs: let lhs, rhs: let rhs):
      return "(\(lhs.description) < \(rhs.description))"
    case ._additionList(let list):
      return "(\(list.entries.map({ "\($0.factor) (*) [\($0.conditions.map({ $0.description }).joined(separator: " && "))] (*) \($0.term.description)" }).joined(separator: " + ")))"
    case ._sub(lhs: let lhs, rhs: let rhs):
      return "\(lhs.description) - \(rhs.description)"
    case ._mul(terms: let terms):
      return "(\(terms.map({ $0.description }).joined(separator: " * ")))"
    case ._div(term: let term, divisors: let divisors):
      return "(\(term.description)) / \(divisors.map(\.description).joined(separator: " / "))"
    case ._zeroDiv(term: let term, divisors: let divisors):
      return "(\(term.description)) ./. \(divisors.map(\.description).joined(separator: " ./. "))"
    }
  }
  
  public var treeDescription: String {
    switch self {
    case .variable(let variable):
      return "▷ \(variable.description)"
    case .number(let value):
      return "▷ \(value.description)"
    case .bool(let value):
      return "▷ \(value.description)"
    case ._not(let term):
      return """
      ▽ Negated
      \(term.treeDescription.indented())
      """
    case ._iverson(let term):
      return """
      ▽ Bool to int
      \(term.treeDescription.indented())
      """
    case ._equal(lhs: let lhs, rhs: let rhs):
      return """
      ▽ =
      \(lhs.treeDescription.indented())
      \(rhs.treeDescription.indented())
      """
    case ._lessThan(lhs: let lhs, rhs: let rhs):
      return """
      ▽ <
      \(lhs.treeDescription.indented())
      \(rhs.treeDescription.indented())
      """
    case ._additionList(let list):
      var description = "▽ +"
      for entry in list.entries {
        description += """
          
            ▽ (*)
              ▷ \(entry.factor)
              ▷ \(entry.conditions.map({ $0.description }).joined(separator: " && "))
          \(entry.term.treeDescription.indented(2))
          """
      }
      return description
    case ._sub(lhs: let lhs, rhs: let rhs):
      return """
      ▽ -
      \(lhs.treeDescription.indented())
      \(rhs.treeDescription.indented())
      """
    case ._mul(terms: let terms):
      return "▽ *\n\(terms.map({ $0.treeDescription.indented() }).joined(separator: "\n"))"
    case ._div(term: let term, divisors: let divisors):
      return """
      ▽ /
      \(term.treeDescription.indented())
      \(divisors.map({ $0.treeDescription.indented() }).joined(separator: "\n"))
      """
    case ._zeroDiv(term: let term, divisors: let divisors):
      return """
      ▽ */*
      \(term.treeDescription.indented())
      \(divisors.map({ $0.treeDescription.indented() }).joined(separator: "\n"))
      """
    }
  }
}

// MARK: - Replacing terms

public extension Term {
  /// Replace the `variable` with the given `term`.
  /// Returns the updated term or `nil` if no replacement was performed.
  func replacing(variable: SourceVariable, with replacementTerm: Term) -> Term? {
    switch self {
    case .variable(let myVariable):
      if myVariable == variable {
        return replacementTerm
      } else {
        return nil
      }
    case .number:
      return nil
    case .bool:
      return nil
    case ._not(let wrappedBool):
      if let replaced = wrappedBool.replacing(variable: variable, with: replacementTerm) {
        return Term._not(replaced).simplified(recursively: false)
      }
      return nil
    case ._iverson(let wrappedBool):
      if let replaced = wrappedBool.replacing(variable: variable, with: replacementTerm) {
        return Term._iverson(replaced).simplified(recursively: false)
      }
      return nil
    case ._equal(lhs: let lhs, rhs: let rhs):
      let lhsReplaced = lhs.replacing(variable: variable, with: replacementTerm)
      let rhsReplaced = rhs.replacing(variable: variable, with: replacementTerm)
      if lhsReplaced == nil && rhsReplaced == nil {
        return nil
      }
      return Term._equal(lhs: lhsReplaced ?? lhs, rhs: rhsReplaced ?? rhs).simplified(recursively: false)
    case ._lessThan(lhs: let lhs, rhs: let rhs):
      let lhsReplaced = lhs.replacing(variable: variable, with: replacementTerm)
      let rhsReplaced = rhs.replacing(variable: variable, with: replacementTerm)
      if lhsReplaced == nil && rhsReplaced == nil {
        return nil
      }
      return Term._lessThan(lhs: lhsReplaced ?? lhs, rhs: rhsReplaced ?? rhs).simplified(recursively: false)
    case ._additionList(var list):
      let performedReplacement = list.replace(variable: variable, with: replacementTerm)
      if performedReplacement {
        return Term._additionList(list).simplified(recursively: false)
      } else {
        return nil
      }
    case ._sub(lhs: let lhs, rhs: let rhs):
      let lhsReplaced = lhs.replacing(variable: variable, with: replacementTerm)
      let rhsReplaced = rhs.replacing(variable: variable, with: replacementTerm)
      if lhsReplaced == nil && rhsReplaced == nil {
        return nil
      }
      return Term._sub(lhs: lhsReplaced ?? lhs, rhs: rhsReplaced ?? rhs).simplified(recursively: false)
    case ._mul(terms: let terms):
      var hasPerformedReplacement = false
      let replacedTerms = terms.map({ (factor) -> Term in
        if let replaced = factor.replacing(variable: variable, with: replacementTerm) {
          hasPerformedReplacement = true
          return replaced
        } else {
          return factor
        }
      })
      if hasPerformedReplacement {
        return Term._mul(terms: replacedTerms).simplified(recursively: false)
      } else {
        return nil
      }
    case ._div(term: let term, divisors: let divisors):
      let termReplaced = term.replacing(variable: variable, with: replacementTerm)
      let divisorsReplaced = divisors.replacing(variable: variable, with: replacementTerm)
      if termReplaced == nil, divisorsReplaced == nil {
        return nil
      }
      return Term._div(term: termReplaced ?? term, divisors: divisorsReplaced ?? divisors).simplified(recursively: false)
    case ._zeroDiv(term: let term, divisors: let divisors):
      let termReplaced = term.replacing(variable: variable, with: replacementTerm)
      let divisorsReplaced = divisors.replacing(variable: variable, with: replacementTerm)
      if termReplaced == nil, divisorsReplaced == nil {
        return nil
      }
      return Term._zeroDiv(term: termReplaced ?? term, divisors: divisorsReplaced ?? divisors).simplified(recursively: false)
    }
  }
}

// MARK: Simplifying terms

internal extension Term {
  private func selfOrSimplified(simplified: Bool) -> Term {
    if simplified {
      return self.simplified(recursively: true)
    } else {
      return self
    }
  }
  
  private static func simplifyNot(term: Term, recursively: Bool) -> Term {
    switch term.selfOrSimplified(simplified: recursively) {
    case .bool(false):
      return .bool(true)
    case .bool(true):
      return .bool(false)
    case ._not(let doubleNegated):
      return doubleNegated
    case let simplifiedTerm:
      return ._not(simplifiedTerm)
    }
  }
  
  private static func simplifyBoolToInt(term: Term, recursively: Bool) -> Term {
    switch term.selfOrSimplified(simplified: recursively) {
    case .bool(false):
      return .number(0)
    case .bool(true):
      return .number(1)
    case let simplifiedTerm:
      return ._iverson(simplifiedTerm)
    }
  }
  
  private static func simplifyEqual(lhs: Term, rhs: Term, recursively: Bool) -> Term {
    switch (lhs.selfOrSimplified(simplified: recursively), rhs.selfOrSimplified(simplified: recursively)) {
    case (.number(let lhsValue), .number(let rhsValue)):
      return .bool(lhsValue == rhsValue)
    case (.bool(let lhsValue), .bool(let rhsValue)):
      return .bool(lhsValue == rhsValue)
    case (let value, .bool(true)), (.bool(true), let value):
      return value
    case (let value, .bool(false)), (.bool(false), let value):
      return ._not(value)
    case (let lhsValue, let rhsValue):
      return ._equal(lhs: lhsValue, rhs: rhsValue)
    }
  }
  
  private static func simplifyLessThan(lhs: Term, rhs: Term, recursively: Bool) -> Term {
    switch (lhs.selfOrSimplified(simplified: recursively), rhs.selfOrSimplified(simplified: recursively)) {
    case (.number(let lhsValue), .number(let rhsValue)):
      return .bool(lhsValue < rhsValue)
    case (let lhsValue, let rhsValue):
      return ._lessThan(lhs: lhsValue, rhs: rhsValue)
    }
  }
  
  private static func simplifyAdditionList(list: AdditionList, recursively: Bool) -> Term {
    var list = list
    if recursively {
      for (index, entry) in list.entries.enumerated() {
        list.entries[index] = TermAdditionListEntry(
          factor: entry.factor,
          conditions: Set(entry.conditions.map({ $0.simplified(recursively: recursively) })),
          term: entry.term.simplified(recursively: recursively)
        )
      }
    }
    list.simplify()
    
    if list.entries.count == 0 {
      return .number(0)
    } else if list.entries.count == 1 {
      let entry = list.entries.first!
      var factors: [Term] = [entry.term]
      if entry.factor != 1 {
        factors.append(.number(entry.factor))
      }
      for condition in entry.conditions {
        factors.append(.iverson(condition))
      }
      return .mul(terms: factors)
    } else {
      return ._additionList(list)
    }
  }
  
  private static func simplifySub(lhs: Term, rhs: Term, recursively: Bool) -> Term {
    switch (lhs.selfOrSimplified(simplified: recursively), rhs.selfOrSimplified(simplified: recursively)) {
    case (let lhs, .number(0)):
      return lhs
    case (.number(let lhsValue), .number(let rhsValue)):
      return .number(lhsValue - rhsValue)
    case (let lhsValue, let rhsValue):
      return ._sub(lhs: lhsValue, rhs: rhsValue)
    }
  }
  
  private static func simplifyMul(terms: [Term], recursively: Bool) -> Term {
    var terms = terms
    var singleAdditionListIndex: Int?
    
    // Flatten nested multiplications and check if the multiplication contains a single addition list
    for index in (0..<terms.count).reversed() {
      let term = terms[index]
      if case ._mul(terms: let subTerms) = term {
        terms.remove(at: index)
        terms.append(contentsOf: subTerms)
      }
      if case ._additionList = term {
        if singleAdditionListIndex == nil {
          singleAdditionListIndex = index
        } else {
          singleAdditionListIndex = nil
        }
      }
    }
    
    if let singleAdditionListIndex = singleAdditionListIndex {
      guard case ._additionList(var additionList) = terms[singleAdditionListIndex] else {
        fatalError()
      }
      terms.remove(at: singleAdditionListIndex)
      additionList.multiply(with: terms)
      return Term._additionList(additionList)
    }
    
    var constantComponent = 1.0
    var otherComponents: [Term] = []
    for term in terms {
      switch term.selfOrSimplified(simplified: recursively) {
      case .number(let value):
        constantComponent *= value
      case ._iverson(let subTerm):
        if otherComponents.contains(.iverson(.not(subTerm))) {
          return .number(0)
        } else if !otherComponents.contains(term) {
          otherComponents.append(term)
        }
      case let simplifiedTerm:
        otherComponents.append(simplifiedTerm)
      }
    }
    var finalTerms = otherComponents
    if constantComponent == 0 {
      return .number(0)
    }
    // Sort the double components by size before adding them since this is numerically more stable
    if constantComponent != 1 {
      finalTerms.append(.number(constantComponent))
    }
    if finalTerms.count == 0 {
      return .number(1)
    } else if finalTerms.count == 1 {
      return finalTerms.first!
    } else {
      return ._mul(terms: finalTerms)
    }
  }
  
  func simplifyDiv(term: Term, divisors: [Term], zeroDiv: Bool, recursively: Bool) -> Term {
    var term = term.selfOrSimplified(simplified: recursively)
    var divisors = divisors
    if recursively {
      divisors = divisors.map({ $0.simplified(recursively: recursively) })
    }
    
    var constantComponent = 1.0
    var otherComponents: [Term] = []
    
    // Flatten term
    switch term {
    case ._div(term: let nestedTerm, divisors: let nestedDivisors):
      term = nestedTerm
      divisors += nestedDivisors
    default:
      break
    }
    
    // Flatten the divisors
    for divisor in divisors {
      switch divisor {
      case .number(let value):
        constantComponent *= value
      case ._mul(terms: let terms):
        otherComponents.append(contentsOf: terms)
      default:
        otherComponents.append(divisor)
      }
    }
    
    /// If possible, cancel this term from the division's `term` with entries in `otherComponents` or combine it with the `constantComponent`.
    /// If the term could be (partially) cancelled, returns the new term. If no cancellation was performed, returns `nil`.
    /// `otherComponents` etc. are updated by this function.
    func tryToCancelTerm(termToCancel: Term) -> Term? {
      switch termToCancel {
      case .number(let value) where value != 0:
        constantComponent /= value
        return .number(1)
      case ._iverson where zeroDiv:
        // If we want to have 0 / 0 = 0, and have a condition in both the term and divisors, we can remove it from the divisors but not from the term.
        // Otherwise, we can cancel the terms in the default case
        if let otherComponentsIndex = otherComponents.firstIndex(of: termToCancel) {
          otherComponents.remove(at: otherComponentsIndex)
        }
        return nil
      case ._additionList(var additionList):
        otherComponents = additionList.tryDividing(by: otherComponents)
        if constantComponent != 1 {
          additionList.divide(by: constantComponent)
          constantComponent = 1
        }
        return Term._additionList(additionList).simplified(recursively: false)
      case _ where !zeroDiv:
        // We can only cancel terms if we don't define 0 / 0 = 0
        if let otherComponentsIndex = otherComponents.firstIndex(of: termToCancel) {
          otherComponents.remove(at: otherComponentsIndex)
          return .number(1)
        } else {
          return nil
        }
      default:
        return nil
      }
    }
    
    // Perform simplifications on term that don't completely evaluate it
    switch term {
    case ._mul(terms: var multiplicationTerms):
      for multiplicationTermIndex in (0..<multiplicationTerms.count).reversed() {
        let multiplicationTerm = multiplicationTerms[multiplicationTermIndex]
        if let cancelledTerm = tryToCancelTerm(termToCancel: multiplicationTerm) {
          multiplicationTerms[multiplicationTermIndex] = cancelledTerm
        }
      }
      term = Term._mul(terms: multiplicationTerms).simplified(recursively: false)
    default:
      if let cancelledTerm = tryToCancelTerm(termToCancel: term) {
        term = cancelledTerm
      }
    }
    
    // Evaluate the term if it has been sufficiently simplified
    if otherComponents.isEmpty {
      switch term {
      case .number(0):
        return .number(0)
      case .number(let value):
        return .number(value / constantComponent)
      default:
        if constantComponent == 1 {
          return term
        } else {
          return ._div(term: term, divisors: [.number(constantComponent)])
        }
      }
    } else {
      return ._div(term: term, divisors: divisors)
    }
  }
  
  func simplified(recursively: Bool) -> Term {
    switch self {
    case .variable:
      return self
    case .number:
      return self
    case .bool:
      return self
    case ._not(let term):
      return Self.simplifyNot(term: term, recursively: recursively)
    case ._iverson(let term):
      return Self.simplifyBoolToInt(term: term, recursively: recursively)
    case ._equal(lhs: let lhs, rhs: let rhs):
      return Self.simplifyEqual(lhs: lhs, rhs: rhs, recursively: recursively)
    case ._lessThan(lhs: let lhs, rhs: let rhs):
      return Self.simplifyLessThan(lhs: lhs, rhs: rhs, recursively: recursively)
    case ._additionList(let list):
      return Self.simplifyAdditionList(list: list, recursively: recursively)
    case ._sub(lhs: let lhs, rhs: let rhs):
      return Self.simplifySub(lhs: lhs, rhs: rhs, recursively: recursively)
    case ._mul(terms: let terms):
      return Self.simplifyMul(terms: terms, recursively: recursively)
    case ._div(term: let term, divisors: let divisors):
      return simplifyDiv(term: term, divisors: divisors, zeroDiv: false, recursively: recursively)
    case ._zeroDiv(term: let term, divisors: let divisors):
      return simplifyDiv(term: term, divisors: divisors, zeroDiv: true, recursively: recursively)
    }
  }
}

// MARK: - Contains Variable

public extension Term {
  func contains(variable: SourceVariable) -> Bool {
    switch self {
    case .variable(let specifiedVariable):
      return specifiedVariable == variable
    case .number, .bool:
      return false
    case ._not(let wrapped), ._iverson(let wrapped):
      return wrapped.contains(variable: variable)
    case ._equal(lhs: let lhs, rhs: let rhs), ._lessThan(lhs: let lhs, rhs: let rhs), ._sub(lhs: let lhs, rhs: let rhs):
      return lhs.contains(variable: variable) || rhs.contains(variable: variable)
    case ._additionList(let additionList):
      return additionList.contains(variable: variable)
    case ._mul(terms: let terms):
      return terms.contains(where: { $0.contains(variable: variable) })
    case ._div(term: let term, divisors: let divisors):
      return term.contains(variable: variable) || divisors.contains(where: { $0.contains(variable: variable) })
    case ._zeroDiv(term: let term, divisors: let divisors):
      return term.contains(variable: variable) || divisors.contains(where: { $0.contains(variable: variable) })
    }
  }
}

// MARK: - Utility functions

public extension Term {
  var doubleValue: Double {
    switch self {
    case .number(let value):
      return value
    case let simplifiedTerm:
      fatalError("""
        WP evaluation term was not fully simplified
        Term:
        \(simplifiedTerm)

        Original:
        \(self)
        """)
    }
  }
}

public extension Term {
  /// Convenience function to construct a term of the form `[variable = value]`
  static func probability(of variable: SourceVariable, equalTo value: Term) -> Term {
    return .iverson(.equal(lhs: .variable(variable), rhs: value))
  }
}

// MARK: - Operators

infix operator ./.: MultiplicationPrecedence

public func +(lhs: Term, rhs: Term) -> Term {
  return Term.add(terms: [lhs, rhs])
}

public func -(lhs: Term, rhs: Term) -> Term {
  return Term.sub(lhs: lhs, rhs: rhs)
}

public func *(lhs: Term, rhs: Term) -> Term {
  return Term.mul(terms: [lhs, rhs])
}

public func /(lhs: Term, rhs: Term) -> Term {
  return Term.div(lhs: lhs, rhs: rhs)
}

public func ./.(lhs: Term, rhs: Term) -> Term {
  return Term.zeroDiv(lhs: lhs, rhs: rhs)
}
