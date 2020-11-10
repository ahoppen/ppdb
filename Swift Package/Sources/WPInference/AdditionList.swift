import AST
import Utils

public struct TermAdditionListEntry: Hashable {
  public fileprivate(set) var factor: Double
  public fileprivate(set) var conditions: Set<Term>
  public fileprivate(set) var term: Term
  
  fileprivate var isZero: Bool {
    if factor == 0 {
      return true
    }
    if term == .number(0) {
      return true
    }
    
    if conditions.contains(.bool(false)) {
      return true
    }
    for condition in conditions {
      if case ._not(let wrapped) = condition {
        if conditions.contains(wrapped) {
          return true
        }
      }
    }
    return false
  }
  
  fileprivate func contains(variable: SourceVariable) -> Bool {
    return conditions.contains(where: { $0.contains(variable: variable) }) || term.contains(variable: variable)
  }
  
  internal mutating func replace(variable: SourceVariable, with replacementTerm: Term) -> Bool {
    var hasPerformedReplacement = false
    if let replacedTerm = self.term.replacing(variable: variable, with: replacementTerm) {
      hasPerformedReplacement = true
      self.term = replacedTerm
    }
    for conditionTerm in conditions {
      if let replacedCondition = conditionTerm.replacing(variable: variable, with: replacementTerm) {
        hasPerformedReplacement = true
        conditions.remove(conditionTerm)
        if replacedCondition != .bool(true) {
          conditions.insert(replacedCondition)
        }
      }
    }
    return hasPerformedReplacement
  }
  
  fileprivate func replacing(variable: SourceVariable, with replacementTerm: Term) -> TermAdditionListEntry? {
    var entry = self
    let performedReplacement = entry.replace(variable: variable, with: replacementTerm)
    if performedReplacement {
      return entry
    } else {
      return nil
    }
  }
}

/// An addition list adds terms of the following form: `factor * [conditions] * term`
///  - `factor`: A constant factor associated with the term
///  - `conditions`: A list of conditiosn that all need to be satisfied for the resulting term to not be zero
///  - `term`: A `Term` that is being added.
/// The handling of the special cases `factor` and `conditions` allows for easier simplification of addition lists.
public struct AdditionList: Hashable {
  public internal(set) var entries: [TermAdditionListEntry]
  
  public init(_ entries: [TermAdditionListEntry]) {
    self.entries = entries
  }
  
  internal func contains(variable: SourceVariable) -> Bool {
    return entries.contains(where: { $0.contains(variable: variable) })
  }
  
  internal mutating func replace(variable: SourceVariable, with term: Term) -> Bool {
    var hasPerformedReplacement = false
    for (index, entry) in entries.enumerated() {
      if let replacedEntry = entry.replacing(variable: variable, with: term) {
        entries[index] = replacedEntry
        hasPerformedReplacement = true
      }
    }
    return hasPerformedReplacement
  }
  
  internal mutating func multiply(with multiplicationTerms: [Term]) {
    for index in 0..<entries.count {
      entries[index].term = Term.mul(terms: [entries[index].term] + multiplicationTerms)
    }
    simplify()
  }
  
  internal mutating func simplify() {
    normalize()
    mergeConditions()
    mergeDuplicateEntries()
  }
  
  private mutating func increaseFactor(of term: Term, conditions: Set<Term>, by factorIncrease: Double) {
    if let existingEntryIndex = entries.firstIndex(where: { $0.term == term && $0.conditions == conditions }) {
      let existingEntryFactor = entries[existingEntryIndex].factor
      entries[existingEntryIndex] = TermAdditionListEntry(factor: existingEntryFactor + factorIncrease, conditions: conditions, term: term)
    } else {
      entries += TermAdditionListEntry(factor: factorIncrease, conditions: conditions, term: term)
    }
  }
  
  /// Try merging terms with equal factors and terms where one entry contains a condition of the form `x && ...` and the other contains `!x && ...`
  private mutating func mergeConditions() {
    var hasConverged = false
    while !hasConverged {
      hasConverged = mergeConditionsImpl()
    }
  }
  
  /// Try merging terms with equal factors and terms where one entry contains a condition of the form `x && ...` and the other contains `!x && ...`
  /// Returns `true` if entries were merged and `false` otherwise.
  private mutating func mergeConditionsImpl() -> Bool {
    var hasMergedEntries = false
    for index in (0..<entries.count).reversed() {
      let entry = entries[index]
      for conditionToFlip in entry.conditions {
        var conditionsWithOneConditionFlipped = entry.conditions
        conditionsWithOneConditionFlipped.remove(conditionToFlip)
        conditionsWithOneConditionFlipped.insert(.not(conditionToFlip))
        let entryWithConditionFlipped = TermAdditionListEntry(
          factor: entry.factor,
          conditions: conditionsWithOneConditionFlipped,
          term: entry.term
        )
        if let otherIndex = entries[0..<index].firstIndex(of: entryWithConditionFlipped) {
          var conditionsWithConditionRemoved = entry.conditions
          conditionsWithConditionRemoved.remove(conditionToFlip)
          hasMergedEntries = true
          entries.remove(at: index)
          entries[otherIndex] = TermAdditionListEntry(
            factor: entry.factor,
            conditions: conditionsWithConditionRemoved,
            term: entry.term
          )
          break
        }
      }
    }
    return !hasMergedEntries
  }
  
  private mutating func normalize() {
    for (index, var entry) in entries.enumerated().reversed() {
      if entry.isZero {
        entries.remove(at: index)
        continue
      }
      
      // Remove any constant true conditions as they are superflous.
      if entry.conditions.remove(.bool(true)) != nil {
        entries[index] = entry
      }
      
      // Perform further normalizations
      switch entry.term {
      case .number(let value) where value != 1:
        entries.remove(at: index)
        self.increaseFactor(of: .number(1), conditions: entry.conditions, by: entry.factor * value)
      case ._iverson(let condition):
        // Hoist conditions into the condition part of the AdditionListEntry
        entries.remove(at: index)
        if !entry.conditions.contains(.not(condition)) {
          self.increaseFactor(of: .number(1), conditions: entry.conditions.union([condition]), by: entry.factor)
        }
      case ._mul(terms: var factors):
        // Extract any constants and conditions from a multiplication
        var wasSimplified = false
        
        for (index, multiplicationFactorTerm) in factors.enumerated().reversed() {
          switch multiplicationFactorTerm {
          case .number(let value):
            entry.factor *= value
            wasSimplified = true
            factors.remove(at: index)
          case ._iverson(let condition):
            entry.conditions.insert(condition)
            wasSimplified = true
            factors.remove(at: index)
          default:
            break
          }
        }
        if wasSimplified {
          entry.term = Term.mul(terms: factors)
          entries[index] = entry
        }
      case ._additionList(let nestedList):
        // Flatten nested addition lists. The nested list is already normalized
        entries.remove(at: index)
        for nestedEntry in nestedList.entries {
          self.increaseFactor(of: nestedEntry.term, conditions: entry.conditions.union(nestedEntry.conditions), by: nestedEntry.factor * entry.factor)
        }
      default:
        break
      }
    }
  }
  
  private mutating func mergeDuplicateEntries() {
    var indiciesToRemove: [Int] = []
    for index in 0..<entries.count {
      let entry = entries[index]
      if let otherIndex = entries[(index + 1)...].firstIndex(where: { $0.term == entry.term && $0.conditions == entry.conditions }) {
        let otherEntry = entries[otherIndex]
        entries[otherIndex] = TermAdditionListEntry(factor: entry.factor + otherEntry.factor, conditions: entry.conditions, term: entry.term)
        indiciesToRemove.append(index)
      }
    }
    for index in indiciesToRemove.reversed() {
      entries.remove(at: index)
    }
  }
  
  /// Divide all entries in the addition list by the given constant
  mutating func divide(by divisor: Double) {
    for index in 0..<entries.count {
      entries[index].factor /= Double(divisor)
    }
  }
  
  /// Try dividing the entries in the addition list by the given `divisors`.
  /// Returns the terms for which division was not able to cancel out terms in the addition list.
  mutating func tryDividing(by divisors: [Term]) -> [Term] {
    var remainingDivisors: [Term] = []
    for divisor in divisors {
      switch divisor {
      case .number(let value):
        for index in 0..<entries.count {
          entries[index].factor /= value
        }
      case ._iverson(let wrapped):
        if entries.allSatisfy({ $0.conditions.contains(wrapped) }) {
          for index in 0..<entries.count {
            entries[index].conditions.remove(wrapped)
          }
        } else {
          remainingDivisors.append(divisor)
        }
      default:
        remainingDivisors.append(divisor)
      }
    }
    return remainingDivisors
  }
}
