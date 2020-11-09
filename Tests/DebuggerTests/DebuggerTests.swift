import AST
import ExecutionHistory
import Debugger

import XCTest

class DebuggerTests: XCTestCase {
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
      
      let varX = SourceVariable(name: "x", disambiguationIndex: 1, type: .int)
      
      let debugger = try Debugger(sourceCode: source, numSamples: 1000)
      
      XCTAssertEqual(debugger.sampledVariableValues, [:])
      
      debugger.stepOver()
      
      XCTAssertEqual(debugger.sampledVariableValues, [
        varX: [.integer(0): 1]
      ])
      XCTAssertEqual(debugger.variableValuesUsingWP, [
        varX: [.integer(0): 1...1]
      ])
      
      debugger.stepOver()

      XCTAssertEqual(debugger.sampledVariableValues[varX]![.integer(0)]!, 0.2, accuracy: 0.1)
      XCTAssertEqual(debugger.sampledVariableValues[varX]![.integer(1)]!, 0.8, accuracy: 0.1)
      XCTAssertEqual(debugger.variableValuesUsingWP[varX]![.integer(0)]!.lowerBound, 0.2, accuracy: 0.0000001)
      XCTAssertEqual(debugger.variableValuesUsingWP[varX]![.integer(0)]!.upperBound, 0.2, accuracy: 0.0000001)
      XCTAssertEqual(debugger.variableValuesUsingWP[varX]![.integer(1)]!.lowerBound, 0.8, accuracy: 0.0000001)
      XCTAssertEqual(debugger.variableValuesUsingWP[varX]![.integer(1)]!.upperBound, 0.8, accuracy: 0.0000001)

      debugger.stepIntoTrue()

      XCTAssertEqual(debugger.sampledVariableValues[varX]![.integer(0)]!, 1, accuracy: 0.1)
      XCTAssertEqual(debugger.variableValuesUsingWP, [
        varX: [.integer(0): 1...1]
      ])

      debugger.stepOver()

      XCTAssertEqual(debugger.sampledVariableValues[varX]![.integer(2)]!, 1, accuracy: 0.1)
      XCTAssertEqual(debugger.variableValuesUsingWP, [
        varX: [.integer(2): 1...1]
      ])
    }())
  }
}

