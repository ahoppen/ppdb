import AST
import Parser
import TypeChecker
import WPInference

import XCTest

fileprivate func XCTAssertEqualInferenceResult(_ lhs: InferenceResult, wpf: Double, accuracy: Double = 0.00000001) {
  if case .number(let value) = lhs.wpf {
    XCTAssertEqual(value, wpf, accuracy: accuracy)
  } else {
    XCTFail("wpf component is not a number but \(lhs.wpf)")
  }
}

fileprivate extension SourceRange {
  func sourceCode(in sourceCode: String) -> String {
    return String(sourceCode[lowerBound.offset..<upperBound.offset])
  }
}

fileprivate extension Term {
  static func probability(of variable: SourceVariable, being term: Term) -> Term {
    return Term.iverson(Term.equal(lhs: .variable(variable), rhs: term).simplified).simplified
  }
}

class HistoryInferenceEngineTests: XCTestCase {
  private func parse(_ sourceCode: String) throws -> TopLevelCodeStmt {
    let parser = Parser(sourceCode: sourceCode)
    let ast = try parser.parseFile()
    return try TypeCheckPipeline.typeCheck(stmt: ast) as! TopLevelCodeStmt
  }
  
  func testStepOverStraightLineProgram() {
    XCTAssertNoThrow(try {
      let source = """
      int x = 5
      x = x + 2
      x = x + 3
      """
      
      let ast = try parse(source)
      let varX = SourceVariable(name: "x", disambiguationIndex: 1, type: .int)
      
      XCTAssertEqualInferenceResult(HistoryInferenceEngine.infer(history: [.stepOver], ast: ast, f: .probability(of: varX, being: .number(5))),
                                    wpf: 1
      )
      XCTAssertEqualInferenceResult(HistoryInferenceEngine.infer(history: [.stepOver], ast: ast, f: .probability(of: varX, being: .number(7))),
                                    wpf: 0
      )
      XCTAssertEqualInferenceResult(HistoryInferenceEngine.infer(history: [.stepOver], ast: ast, f: .probability(of: varX, being: .number(10))),
                                    wpf: 0
      )
      
      XCTAssertEqualInferenceResult(HistoryInferenceEngine.infer(history: [.stepOver, .stepOver], ast: ast, f: .probability(of: varX, being: .number(5))),
                                    wpf: 0
      )
      XCTAssertEqualInferenceResult(HistoryInferenceEngine.infer(history: [.stepOver, .stepOver], ast: ast, f: .probability(of: varX, being: .number(7))),
                                    wpf: 1
      )
      XCTAssertEqualInferenceResult(HistoryInferenceEngine.infer(history: [.stepOver, .stepOver], ast: ast, f: .probability(of: varX, being: .number(10))),
                                    wpf: 0
      )
      
      XCTAssertEqualInferenceResult(HistoryInferenceEngine.infer(history: [.stepOver, .stepOver, .stepOver], ast: ast, f: .probability(of: varX, being: .number(5))),
                                    wpf: 0
      )
      XCTAssertEqualInferenceResult(HistoryInferenceEngine.infer(history: [.stepOver, .stepOver, .stepOver], ast: ast, f: .probability(of: varX, being: .number(7))),
                                    wpf: 0
      )
      XCTAssertEqualInferenceResult(HistoryInferenceEngine.infer(history: [.stepOver, .stepOver, .stepOver], ast: ast, f: .probability(of: varX, being: .number(10))),
                                    wpf: 1
      )
    }())
  }
  
  func testProbStatement() {
    XCTAssertNoThrow(try {
      let source = """
      int x = 6
      prob 0.5 {
        x = x + 10
      }
      """
      
      let ast = try parse(source)
      let varX = SourceVariable(name: "x", disambiguationIndex: 1, type: .int)
      
      XCTAssertEqualInferenceResult(HistoryInferenceEngine.infer(history: [.stepOver, .stepOver], ast: ast, f: .probability(of: varX, being: .number(16))),
                                    wpf: 0.5
      )
      XCTAssertEqualInferenceResult(HistoryInferenceEngine.infer(history: [.stepOver, .stepOver], ast: ast, f: .probability(of: varX, being: .number(6))),
                                    wpf: 0.5
      )
      XCTAssertEqualInferenceResult(HistoryInferenceEngine.infer(history: [.stepOver, .stepIntoTrue], ast: ast, f: .probability(of: varX, being: .number(6))),
                                    wpf: 0.5
      )
      XCTAssertEqualInferenceResult(HistoryInferenceEngine.infer(history: [.stepOver, .stepIntoTrue, .stepOver], ast: ast, f: .probability(of: varX, being: .number(16))),
                                    wpf: 0.5
      )
    }())
  }
  
  func testLoop() {
    XCTAssertNoThrow(try {
      let source = """
      int x = 5
      while 0 < x {
        x = x - 1
      }
      """
      
      let ast = try parse(source)
      let varX = SourceVariable(name: "x", disambiguationIndex: 1, type: .int)
      
      XCTAssertEqualInferenceResult(HistoryInferenceEngine.infer(history: [.stepOver], ast: ast, f: .probability(of: varX, being: .number(5))),
                                    wpf: 1
      )
      XCTAssertEqualInferenceResult(HistoryInferenceEngine.infer(history: [.stepOver, .stepIntoTrue], ast: ast, f: .probability(of: varX, being: .number(5))),
                                    wpf: 1
      )
      XCTAssertEqualInferenceResult(HistoryInferenceEngine.infer(history: [.stepOver, .stepIntoTrue, .stepOver], ast: ast, f: .probability(of: varX, being: .number(4))),
                                    wpf: 1
      )
      XCTAssertEqualInferenceResult(HistoryInferenceEngine.infer(history: [.stepOver, .stepIntoTrue, .stepOver, .stepIntoTrue, .stepOver], ast: ast, f: .probability(of: varX, being: .number(3))),
                                    wpf: 1
      )
      XCTAssertEqualInferenceResult(HistoryInferenceEngine.infer(history: [.stepOver, .stepIntoTrue, .stepOver, .stepIntoFalse], ast: ast, f: .probability(of: varX, being: .number(3))),
                                    wpf: 0
      )
    }())
  }
}
