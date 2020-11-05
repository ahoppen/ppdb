import AST
import Parser
import TypeChecker
import TestUtils
import WPInference

import XCTest

fileprivate func XCTAssertEqualInferenceResult(_ lhs: InferenceResult, wpf: Double, wp1: Double, wlp1: Double, wlp0: Double, accuracy: Double = 0.00000001) {
  if case .number(let value) = lhs.wpf {
    XCTAssertEqual(value, wpf, accuracy: accuracy)
  } else {
    XCTFail("wpf component is not a number but \(lhs.wpf)")
  }
  if case .number(let value) = lhs.wp1 {
    XCTAssertEqual(value, wp1, accuracy: accuracy)
  } else {
    XCTFail("wp1 component is not a number but \(lhs.wp1)")
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

class InferenceEngineTests: XCTestCase {
  private func parse(_ sourceCode: String) throws -> Stmt {
    let parser = Parser(sourceCode: sourceCode)
    let ast = try parser.parseFile()
    return try TypeCheckPipeline.typeCheck(stmt: ast)
  }
  
  func testExecuteSingleStatementProgram() {
    XCTAssertNoThrow(try {
      let source = """
        int x = 5
        """
      
      let ast = try parse(source)
      let varX = SourceVariable(name: "x", disambiguationIndex: 1, type: .int)
      
      XCTAssertEqualInferenceResult(
        InferenceEngine.infer(
          stmt: ast,
          loopIterationBounds: [:],
          f: .probability(of: varX, equalTo: .number(5))
        ),
        wpf: 1,
        wp1: 1,
        wlp1: 1,
        wlp0: 0
      )
      XCTAssertEqualInferenceResult(
        InferenceEngine.infer(
          stmt: ast,
          loopIterationBounds: [:],
          f: .probability(of: varX, equalTo: .number(6))
        ),
        wpf: 0,
        wp1: 1,
        wlp1: 1,
        wlp0: 0
      )
    }())
  }
  
  func testExecuteMultiStatementProgram() {
    XCTAssertNoThrow(try {
      let source = """
        int x = 5
        int y = 2
        int z = x + y
        """
      
      let ast = try parse(source)
      let varZ = SourceVariable(name: "z", disambiguationIndex: 1, type: .int)
      
      XCTAssertEqualInferenceResult(
        InferenceEngine.infer(
          stmt: ast,
          loopIterationBounds: [:],
          f: .probability(of: varZ, equalTo: .number(7))
        ),
        wpf: 1,
        wp1: 1,
        wlp1: 1,
        wlp0: 0
      )
      XCTAssertEqualInferenceResult(
        InferenceEngine.infer(
          stmt: ast,
          loopIterationBounds: [:],
          f: .probability(of: varZ, equalTo: .number(6))
        ),
        wpf: 0,
        wp1: 1,
        wlp1: 1,
        wlp0: 0
      )
    }())
  }
  
  func testExecuteProbabilisticProgram() {
    XCTAssertNoThrow(try {
      let source = """
        int x = 0
        prob 0.8 {
          x = 1
        }
        """
      
      let ast = try parse(source)
      let varX = SourceVariable(name: "x", disambiguationIndex: 1, type: .int)
      
      XCTAssertEqualInferenceResult(
        InferenceEngine.infer(
          stmt: ast,
          loopIterationBounds: [:],
          f: .probability(of: varX, equalTo: .number(0))
        ),
        wpf: 0.2,
        wp1: 1,
        wlp1: 1,
        wlp0: 0
      )
      XCTAssertEqualInferenceResult(
        InferenceEngine.infer(
          stmt: ast,
          loopIterationBounds: [:],
          f: .probability(of: varX, equalTo: .number(1))
          ),
        wpf: 0.8,
        wp1: 1,
        wlp1: 1,
        wlp0: 0
      )
      XCTAssertEqualInferenceResult(
        InferenceEngine.infer(
          stmt: ast,
          loopIterationBounds: [:],
          f: .probability(of: varX, equalTo: .number(2))
        ),
        wpf: 0,
        wp1: 1,
        wlp1: 1,
        wlp0: 0
      )
    }())
  }
  
  func testExecuteProbabilisticProgramWithIf() {
    XCTAssertNoThrow(try {
      let source = """
        int x = 0
        prob 0.8 {
          x = 1
        }
        if x == 0 {
          x = 2
        }
        """
      
      let ast = try parse(source)
      let varX = SourceVariable(name: "x", disambiguationIndex: 1, type: .int)
      
      XCTAssertEqualInferenceResult(
        InferenceEngine.infer(
          stmt: ast,
          loopIterationBounds: [:],
          f: .probability(of: varX, equalTo: .number(0))
        ),
        wpf: 0,
        wp1: 1,
        wlp1: 1,
        wlp0: 0
      )
      XCTAssertEqualInferenceResult(
        InferenceEngine.infer(
          stmt: ast,
          loopIterationBounds: [:],
          f: .probability(of: varX, equalTo: .number(1))
        ),
        wpf: 0.8,
        wp1: 1,
        wlp1: 1,
        wlp0: 0
      )
      XCTAssertEqualInferenceResult(
        InferenceEngine.infer(
          stmt: ast,
          loopIterationBounds: [:],
          f: .probability(of: varX, equalTo: .number(2))
        ),
        wpf: 0.2,
        wp1: 1,
        wlp1: 1,
        wlp0: 0
      )
    }())
  }
  
  func testExecuteDeterministicProgramWithLoop() {
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
        InferenceEngine.infer(
          stmt: ast,
          loopIterationBounds: [LoopId(id: 0): 5],
          f: .probability(of: varX, equalTo: .number(0))
        ),
        wpf: 1,
        wp1: 1,
        wlp1: 1,
        wlp0: 0
      )
      XCTAssertEqualInferenceResult(
        InferenceEngine.infer(
          stmt: ast,
          loopIterationBounds: [LoopId(id: 0): 5],
          f: .probability(of: varX, equalTo: .number(1))
        ),
        wpf: 0,
        wp1: 1,
        wlp1: 1,
        wlp0: 0
      )
      XCTAssertEqualInferenceResult(
        InferenceEngine.infer(
          stmt: ast,
          loopIterationBounds: [LoopId(id: 0): 5],
          f: .probability(of: varX, equalTo: .number(5))
        ),
        wpf: 0,
        wp1: 1,
        wlp1: 1,
        wlp0: 0
      )
    }())
  }
  
  func testGenerateGeometricDistribution() {
    XCTAssertNoThrow(try {
      let source = """
          int x = 0
          bool continue = true
          while continue {
            x = x + 1
            prob 0.5 {
              continue = false
            }
          }
          """
      
      let ast = try parse(source)
      let varX = SourceVariable(name: "x", disambiguationIndex: 1, type: .int)
      
      XCTAssertEqualInferenceResult(
        InferenceEngine.infer(
          stmt: ast,
          loopIterationBounds: [LoopId(id: 0): 10],
          f: .probability(of: varX, equalTo: .number(0))
        ),
        wpf: 0,
        wp1: 1,
        wlp1: 1,
        wlp0: 0,
        accuracy: 0.001
      )
      XCTAssertEqualInferenceResult(
        InferenceEngine.infer(
          stmt: ast,
          loopIterationBounds: [LoopId(id: 0): 10],
          f: .probability(of: varX, equalTo: .number(1))
        ),
        wpf: 0.5,
        wp1: 1,
        wlp1: 1,
        wlp0: 0,
        accuracy: 0.001
      )
      XCTAssertEqualInferenceResult(
        InferenceEngine.infer(
          stmt: ast,
          loopIterationBounds: [LoopId(id: 0): 10],
          f: .probability(of: varX, equalTo: .number(2))
        ),
        wpf: 0.25,
        wp1: 1,
        wlp1: 1,
        wlp0: 0,
        accuracy: 0.001
      )
      XCTAssertEqualInferenceResult(
        InferenceEngine.infer(
          stmt: ast,
          loopIterationBounds: [LoopId(id: 0): 10],
          f: .probability(of: varX, equalTo: .number(3))
        ),
        wpf: 0.125,
        wp1: 1,
        wlp1: 1,
        wlp0: 0,
        accuracy: 0.001
      )
      XCTAssertEqualInferenceResult(
        InferenceEngine.infer(
          stmt: ast,
          loopIterationBounds: [LoopId(id: 0): 1],
          f: .probability(of: varX, equalTo: .number(1))
        ),
        wpf: 0.5,
        wp1: 0.5,
        wlp1: 1,
        wlp0: 0.5,
        accuracy: 0.001
      )
      XCTAssertEqualInferenceResult(
        InferenceEngine.infer(
          stmt: ast,
          loopIterationBounds: [LoopId(id: 0): 2],
          f: .probability(of: varX, equalTo: .number(1))
        ),
        wpf: 0.5,
        wp1: 0.75,
        wlp1: 1,
        wlp0: 0.25,
        accuracy: 0.001
      )
    }())
  }
}
