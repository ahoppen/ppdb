import AST
@testable import WPInference

import XCTest

class TermTests: XCTestCase {
  func testSimplify() {
    let term1: Term = .equal(lhs: .number(1) + .number(1), rhs: .number(2))
    XCTAssertEqual(term1, .bool(true))
    
    let term2: Term = .number(0.5) * .iverson(.equal(lhs: .number(1) + .number(1), rhs: .number(2)))
    XCTAssertEqual(term2, .number(0.5))
    
    let term3: Term = .number(0.5) * .iverson(.equal(lhs: .number(2) + .number(1), rhs: .number(2)))
    XCTAssertEqual(term3, .number(0))
    
    let term4 = term2 + term3
    XCTAssertEqual(term4, .number(0.5))
    
    let term5: Term = .number(5) - .number(1) - .number(1)
    XCTAssertEqual(term5, .number(3))
    
    let var1 = SourceVariable(name: "x1", disambiguationIndex: 1, type: .bool)
    let var2 = SourceVariable(name: "x2", disambiguationIndex: 1, type: .bool)
    
    let additionListEntries = [
      TermAdditionListEntry(factor: 1, conditions: [.variable(var1), .variable(var2)], term: .number(1)),
      TermAdditionListEntry(factor: 1, conditions: [.variable(var1), .not(.variable(var2))], term: .number(1)),
      TermAdditionListEntry(factor: 1, conditions: [.not(.variable(var1)), .variable(var2)], term: .number(1)),
      TermAdditionListEntry(factor: 1, conditions: [.not(.variable(var1)), .not(.variable(var2))], term: .number(1))
    ]
    let additionList = Term._additionList(AdditionList(additionListEntries))
    XCTAssertEqual(additionList.simplified(recursively: false), .number(1))
  }
  
  func testAdditionListMergesConditions() {
    let var1 = SourceVariable(name: "x1", disambiguationIndex: 1, type: .bool)
    let var2 = SourceVariable(name: "x2", disambiguationIndex: 1, type: .bool)
    
    let additionListEntries = [
      TermAdditionListEntry(factor: 1, conditions: [.variable(var1), .variable(var2)], term: .number(1)),
      TermAdditionListEntry(factor: 1, conditions: [.variable(var1), .not(.variable(var2))], term: .number(1)),
      TermAdditionListEntry(factor: 1, conditions: [.not(.variable(var1)), .variable(var2)], term: .number(1)),
      TermAdditionListEntry(factor: 1, conditions: [.not(.variable(var1)), .not(.variable(var2))], term: .number(1))
    ]
    let additionList = Term._additionList(AdditionList(additionListEntries))
    XCTAssertEqual(additionList.simplified(recursively: false), .number(1))
  }
  
  func testAdditionListMergesConditionsInTwoSteps() {
    let var1 = SourceVariable(name: "x1", disambiguationIndex: 1, type: .bool)
    let var2 = SourceVariable(name: "x2", disambiguationIndex: 1, type: .bool)
    
    let additionListEntries = [
      TermAdditionListEntry(factor: 1, conditions: [.variable(var1), .variable(var2)], term: .number(1)),
      TermAdditionListEntry(factor: 1, conditions: [.variable(var1), .not(.variable(var2))], term: .number(1)),
      TermAdditionListEntry(factor: 1, conditions: [.not(.variable(var1))], term: .number(1)),
    ]
    let additionList = Term._additionList(AdditionList(additionListEntries))
    XCTAssertEqual(additionList.simplified(recursively: false), .number(1))
  }
  
  func testAdditionListEntriesWithZeroTermsGetRemoved() {
    let distribution = [0: 0.5, 1: 0.5]
    let var1 = SourceVariable(name: "x1", disambiguationIndex: 1, type: .int)
    let var2 = SourceVariable(name: "x2", disambiguationIndex: 1, type: .int)
    let term = Term.iverson(.equal(lhs: .variable(var1), rhs: .number(0))) * Term.iverson(.not(.equal(lhs: .variable(var2), rhs: .number(1))))
    let terms = distribution.map({ (value, probability) in
      return .number(probability) * (term.replacing(variable: var1, with: .number(Double(value))) ?? term)
    })
    XCTAssertEqual(Term.add(terms: terms), Term.iverson(.not(.equal(lhs: .variable(var2), rhs: .number(1)))) * .number(0.5))
  }
  
  func testRecursivelySimplifyAdditionList() {
    let additionListEntries = [
      TermAdditionListEntry(factor: 1, conditions: [._equal(lhs: .bool(true), rhs: .bool(true))], term: ._mul(terms: [.number(1), .number(2)])),
    ]
    let additionList = Term._additionList(AdditionList(additionListEntries))
    XCTAssertEqual(additionList.simplified(recursively: true), .number(2.0))
  }
  
  func testMergeDuplicateEntriesWithDifferentFactors() {
    let queryVariable = SourceVariable(name: "$query", disambiguationIndex: 1, type: .int)
    
    let condition = Term.iverson(.equal(lhs: .number(1), rhs: .variable(queryVariable)))
    
    let additionTerms: [Term] = [
      condition * .number(20),
      condition * .number(4),
      condition * .number(16),
    ]
    
    XCTAssertEqual(Term.add(terms: additionTerms), condition * .number(40))
  }
  
  func testZeroDividedByZeroIsZero() {
    XCTAssertEqual(Term.number(0) / Term.number(0), Term.number(0))
  }
}
