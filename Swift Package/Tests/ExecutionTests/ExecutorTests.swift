import Execution
import AST
import Parser
import TypeChecker
import TestUtils

import XCTest

class ExecutorTests: XCTestCase {
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
      
      let (samples, loopIterationBounds, _) = Executor.execute(stmt: ast, numSamples: 1)
      XCTAssertEqual(loopIterationBounds, [:])
      XCTAssertEqual(samples.count, 1)
      let sample = samples.first!
      let varX = SourceVariable(name: "x", disambiguationIndex: 1, type: .int)
      XCTAssertEqual(sample.values[varX], .integer(5))
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
      
      let (samples, loopIterationBounds, _) = Executor.execute(stmt: ast, numSamples: 1)
      XCTAssertEqual(loopIterationBounds, [:])
      XCTAssertEqual(samples.count, 1)
      let sample = samples.first!
      let varX = SourceVariable(name: "z", disambiguationIndex: 1, type: .int)
      XCTAssertEqual(sample.values[varX], .integer(7))
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
      
      let (samples, loopIterationBounds, _) = Executor.execute(stmt: ast, numSamples: 1000)
      XCTAssertEqual(loopIterationBounds, [:])
      XCTAssertEqual(samples.count, 1000)
      let varX = SourceVariable(name: "x", disambiguationIndex: 1, type: .int)
      let varXValue = samples.map({ $0.values[varX]!.integer! }).average
      XCTAssertEqual(varXValue, 0.8, accuracy: 0.1)
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
      
      let (samples, loopIterationBounds, _) = Executor.execute(stmt: ast, numSamples: 1000)
      XCTAssertEqual(loopIterationBounds, [:])
      XCTAssertEqual(samples.count, 1000)
      let varX = SourceVariable(name: "x", disambiguationIndex: 1, type: .int)
      let varXValue = samples.map({ $0.values[varX]!.integer! }).average
      XCTAssertEqual(varXValue, 1.2, accuracy: 0.1)
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
      
      let (samples, loopIterationBounds, _) = Executor.execute(stmt: ast, numSamples: 1)
      XCTAssertEqual(loopIterationBounds, [
        LoopId(id: 0): 5
      ])
      XCTAssertEqual(samples.count, 1)
      let sample = samples.first!
      let varX = SourceVariable(name: "x", disambiguationIndex: 1, type: .int)
      XCTAssertEqual(sample.values[varX], .integer(0))
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
      
      let (samples, _, _ ) = Executor.execute(stmt: ast, numSamples: 1000)
      XCTAssertEqual(samples.count, 1000)
      let varX = SourceVariable(name: "x", disambiguationIndex: 1, type: .int)
      let varXValue = samples.map({ $0.values[varX]!.integer! }).average
      XCTAssertEqual(varXValue, 2, accuracy: 0.1)
    }())
  }
}

