import AST
import Parser
import TypeChecker
import TestUtils
import WPInference

import XCTest

fileprivate func XCTAssertEqualInferenceResult(_ lhs: InferenceResult, wpf: Double, accuracy: Double = 0.00000001) {
  if case .number(let value) = lhs.wpf {
    XCTAssertEqual(value, wpf, accuracy: accuracy)
  } else {
    XCTFail("wpf component is not a number but \(lhs.wpf)")
  }
}

class InferenceEngineTests: XCTestCase {
  private func parse(_ sourceCode: String) throws -> [Stmt] {
    let parser = Parser(sourceCode: sourceCode)
    let stmts = try parser.parseFile()
    return try TypeCheckPipeline.typeCheck(stmts: stmts)
  }
  
  func testExecuteSingleStatementProgram() {
    XCTAssertNoThrow(try {
      let source = """
        int x = 5
        """
      
      let stmts = try parse(source)
      let varX = SourceVariable(name: "x", disambiguationIndex: 1, type: .int)
      
      XCTAssertEqualInferenceResult(InferenceEngine.inferProbability(of: varX, being: .number(5), stmts: stmts),
                                    wpf: 1
      )
      XCTAssertEqualInferenceResult(InferenceEngine.inferProbability(of: varX, being: .number(6), stmts: stmts),
                                    wpf: 0
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
      
      let stmts = try parse(source)
      let varZ = SourceVariable(name: "z", disambiguationIndex: 1, type: .int)
      
      XCTAssertEqualInferenceResult(InferenceEngine.inferProbability(of: varZ, being: .number(7), stmts: stmts),
                                    wpf: 1)
      XCTAssertEqualInferenceResult(InferenceEngine.inferProbability(of: varZ, being: .number(6), stmts: stmts),
                                    wpf: 0
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
      
      let stmts = try parse(source)
      let varX = SourceVariable(name: "x", disambiguationIndex: 1, type: .int)
      
      XCTAssertEqualInferenceResult(InferenceEngine.inferProbability(of: varX, being: .number(0), stmts: stmts),
                                    wpf: 0.2
      )
      XCTAssertEqualInferenceResult(InferenceEngine.inferProbability(of: varX, being: .number(1), stmts: stmts),
                                    wpf: 0.8
      )
      XCTAssertEqualInferenceResult(InferenceEngine.inferProbability(of: varX, being: .number(2), stmts: stmts),
                                    wpf: 0
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
      
      let stmts = try parse(source)
      let varX = SourceVariable(name: "x", disambiguationIndex: 1, type: .int)
      
      XCTAssertEqualInferenceResult(InferenceEngine.inferProbability(of: varX, being: .number(0), stmts: stmts),
                                    wpf: 0
      )
      XCTAssertEqualInferenceResult(InferenceEngine.inferProbability(of: varX, being: .number(1), stmts: stmts),
                                    wpf: 0.8
      )
      XCTAssertEqualInferenceResult(InferenceEngine.inferProbability(of: varX, being: .number(2), stmts: stmts),
                                    wpf: 0.2
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
      
      let stmts = try parse(source)
      let varX = SourceVariable(name: "x", disambiguationIndex: 1, type: .int)
      
      XCTAssertEqualInferenceResult(InferenceEngine.inferProbability(of: varX, being: .number(0), stmts: stmts),
                                    wpf: 1
      )
      XCTAssertEqualInferenceResult(InferenceEngine.inferProbability(of: varX, being: .number(1), stmts: stmts),
                                    wpf: 0
      )
      XCTAssertEqualInferenceResult(InferenceEngine.inferProbability(of: varX, being: .number(5), stmts: stmts),
                                    wpf: 0
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
      
      let stmts = try parse(source)
      let varX = SourceVariable(name: "x", disambiguationIndex: 1, type: .int)
      
      XCTAssertEqualInferenceResult(InferenceEngine.inferProbability(of: varX, being: .number(0), stmts: stmts),
                                    wpf: 0
      ) 
      XCTAssertEqualInferenceResult(InferenceEngine.inferProbability(of: varX, being: .number(1), stmts: stmts),
                                    wpf: 0.5
      )
      XCTAssertEqualInferenceResult(InferenceEngine.inferProbability(of: varX, being: .number(2), stmts: stmts),
                                    wpf: 0.25
      )
      XCTAssertEqualInferenceResult(InferenceEngine.inferProbability(of: varX, being: .number(3), stmts: stmts),
                                    wpf: 0.125
      )
    }())
  }
}
