import AST
import Parser
import TypeChecker
import WPInference

import XCTest

fileprivate func XCTAssertEqualInferenceResult(_ lhs: InferenceResult, wpf: Double, woip1: Double, wlp1: Double, wlp0: Double, accuracy: Double = 0.00000001) {
  if case .number(let value) = lhs.wpf {
    XCTAssertEqual(value, wpf, accuracy: accuracy)
  } else {
    XCTFail("wpf component is not a number but \(lhs.wpf)")
  }
  if case .number(let value) = lhs.woip1 {
    XCTAssertEqual(value, woip1, accuracy: accuracy)
  } else {
    XCTFail("woip1 component is not a number but \(lhs.woip1)")
  }
  if case .number(let value) = lhs.wlp1 {
    XCTAssertEqual(value, wlp1, accuracy: accuracy)
  } else {
    XCTFail("wlp1 component is not a number but \(lhs.wlp1)")
  }
  if case .number(let value) = lhs.wlp0 {
    XCTAssertEqual(value, wlp0, accuracy: accuracy)
  } else {
    XCTFail("wlp0 component is not a number but \(lhs.wlp0)")
  }
}

fileprivate extension SourceRange {
  func sourceCode(in sourceCode: String) -> String {
    return String(sourceCode[lowerBound.offset..<upperBound.offset])
  }
}

fileprivate extension Term {
  static func probability(of variable: SourceVariable, being term: Term) -> Term {
    return Term.iverson(Term.equal(lhs: .variable(variable), rhs: term))
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
      
      XCTAssertEqualInferenceResult(
        try HistoryInferenceEngine.infer(history: [.stepOver], loopIterationBounds: [:], ast: ast, f: .probability(of: varX, being: .number(5))),
        wpf: 1,
        woip1: 1,
        wlp1: 1,
        wlp0: 0
      )
      XCTAssertEqualInferenceResult(
        try HistoryInferenceEngine.infer(
          history: [.stepOver],
          loopIterationBounds: [:],
          ast: ast,
          f: .probability(of: varX, being: .number(7))
        ),
        wpf: 0,
        woip1: 1,
        wlp1: 1,
        wlp0: 0
      )
      XCTAssertEqualInferenceResult(
        try HistoryInferenceEngine.infer(
          history: [.stepOver],
          loopIterationBounds: [:],
          ast: ast,
          f: .probability(of: varX, being: .number(10))
        ),
        wpf: 0,
        woip1: 1,
        wlp1: 1,
        wlp0: 0
      )
      
      XCTAssertEqualInferenceResult(
        try HistoryInferenceEngine.infer(
          history: [.stepOver, .stepOver],
          loopIterationBounds: [:],
          ast: ast,
          f: .probability(of: varX, being: .number(5))
        ),
        wpf: 0,
        woip1: 1,
        wlp1: 1,
        wlp0: 0
      )
      XCTAssertEqualInferenceResult(
        try HistoryInferenceEngine.infer(
          history: [.stepOver, .stepOver],
          loopIterationBounds: [:],
          ast: ast,
          f: .probability(of: varX, being: .number(7))
        ),
        wpf: 1,
        woip1: 1,
        wlp1: 1,
        wlp0: 0
      )
      XCTAssertEqualInferenceResult(
        try HistoryInferenceEngine.infer(
          history: [.stepOver, .stepOver],
          loopIterationBounds: [:],
          ast: ast,
          f: .probability(of: varX, being: .number(10))
        ),
        wpf: 0,
        woip1: 1,
        wlp1: 1,
        wlp0: 0
      )
      
      XCTAssertEqualInferenceResult(
        try HistoryInferenceEngine.infer(
          history: [.stepOver, .stepOver, .stepOver],
          loopIterationBounds: [:],
          ast: ast,
          f: .probability(of: varX, being: .number(5))
        ),
        wpf: 0,
        woip1: 1,
        wlp1: 1,
        wlp0: 0
      )
      XCTAssertEqualInferenceResult(
        try HistoryInferenceEngine.infer(
          history: [.stepOver, .stepOver, .stepOver],
          loopIterationBounds: [:],
          ast: ast,
          f: .probability(of: varX, being: .number(7))
        ),
        wpf: 0,
        woip1: 1,
        wlp1: 1,
        wlp0: 0
      )
      XCTAssertEqualInferenceResult(
        try HistoryInferenceEngine.infer(
          history: [.stepOver, .stepOver, .stepOver],
          loopIterationBounds: [:],
          ast: ast,
          f: .probability(of: varX, being: .number(10))
        ),
        wpf: 1,
        woip1: 1,
        wlp1: 1,
        wlp0: 0
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
      
      XCTAssertEqualInferenceResult(
        try HistoryInferenceEngine.infer(
          history: [.stepOver, .stepOver],
          loopIterationBounds: [:],
          ast: ast,
          f: .probability(of: varX, being: .number(16))
        ),
        wpf: 0.5,
        woip1: 1,
        wlp1: 1,
        wlp0: 0
      )
      XCTAssertEqualInferenceResult(
        try HistoryInferenceEngine.infer(
          history: [.stepOver, .stepOver],
          loopIterationBounds: [:],
          ast: ast,
          f: .probability(of: varX, being: .number(6))
        ),
        wpf: 0.5,
        woip1: 1,
        wlp1: 1,
        wlp0: 0
      )
      XCTAssertEqualInferenceResult(
        try HistoryInferenceEngine.infer(
          history: [.stepOver, .stepIntoTrue],
          loopIterationBounds: [:],
          ast: ast,
          f: .probability(of: varX, being: .number(6))
        ),
        wpf: 0.5,
        woip1: 1,
        wlp1: 0.5,
        wlp0: 0
      )
      XCTAssertEqualInferenceResult(
        try HistoryInferenceEngine.infer(
          history: [.stepOver, .stepIntoTrue, .stepOver],
          loopIterationBounds: [:],
          ast: ast,
          f: .probability(of: varX, being: .number(16))
        ),
        wpf: 0.5,
        woip1: 1,
        wlp1: 0.5,
        wlp0: 0
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
      
      XCTAssertEqualInferenceResult(
        try HistoryInferenceEngine.infer(
          history: [.stepOver],
          loopIterationBounds: [LoopId(id: 0): 10],
          ast: ast,
          f: .probability(of: varX, being: .number(5))
        ),
        wpf: 1,
        woip1: 1,
        wlp1: 1,
        wlp0: 0
      )
      XCTAssertEqualInferenceResult(
        try HistoryInferenceEngine.infer(
          history: [.stepOver, .stepIntoTrue],
          loopIterationBounds: [LoopId(id: 0): 10],
          ast: ast,
          f: .probability(of: varX, being: .number(5))
        ),
        wpf: 1,
        woip1: 1,
        wlp1: 1,
        wlp0: 0
      )
      XCTAssertEqualInferenceResult(
        try HistoryInferenceEngine.infer(
          history: [.stepOver, .stepIntoTrue, .stepOver],
          loopIterationBounds: [LoopId(id: 0): 10],
          ast: ast,
          f: .probability(of: varX, being: .number(4))
        ),
        wpf: 1,
        woip1: 1,
        wlp1: 1,
        wlp0: 0
      )
      XCTAssertEqualInferenceResult(
        try HistoryInferenceEngine.infer(
          history: [.stepOver, .stepIntoTrue, .stepOver, .stepIntoTrue, .stepOver],
          loopIterationBounds: [LoopId(id: 0): 10],
          ast: ast,
          f: .probability(of: varX, being: .number(3))
        ),
        wpf: 1,
        woip1: 1,
        wlp1: 1,
        wlp0: 0
      )
      XCTAssertEqualInferenceResult(
        try HistoryInferenceEngine.infer(
          history: [.stepOver, .stepIntoTrue, .stepOver, .stepIntoFalse],
          loopIterationBounds: [LoopId(id: 0): 10],
          ast: ast,
          f: .probability(of: varX, being: .number(3))
        ),
        wpf: 0,
        woip1: 1,
        wlp1: 0,
        wlp0: 0
      )
    }())
  }
}
