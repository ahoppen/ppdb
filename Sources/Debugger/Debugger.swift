import AST
import Execution
import ExecutionHistory
import Parser
import TypeChecker
import WPInference

fileprivate extension Term {
  init(_ variableValue: VariableValue) {
    switch variableValue {
    case .integer(let value):
      self = .number(Double(value))
    case .float(let value):
      self = .number(value)
    case .bool(let value):
      self = .bool(value)
    }
  }
}

public class Debugger {
  // MARK: Static properties
  
  private let sourceCode: String
  private let ast: TopLevelCodeStmt
  private let numSamples: Int
  private let loopIterationBounds: LoopIterationBounds
  private let executionOutline: [ExecutionOutlineNode]
  
  private var executionHistory: ExecutionHistory = []
  private var augmentedExecutionHistory: AugmentedExecutionHistory {
    return executionHistory.augmented(with: ast)
  }
  
  private var sourceLocation: SourceLocation? {
    return self.augmentedExecutionHistory.history.last?.stmt.range.lowerBound
  }
  
  public var samples: [Sample] {
    return HistoryExecutor.execute(history: augmentedExecutionHistory, numSamples: numSamples)
  }
  
  public var sampledVariableValues: [SourceVariable: [VariableValue: Double]] {
    if samples.isEmpty {
      return [:]
    }
    var variableValues: [SourceVariable: [VariableValue: Double]] = [:]
    for variable in samples.first!.values.keys {
      var distribution: [VariableValue: Double] = [:]
      
      for sample in samples {
        let value = sample.values[variable]!
        distribution[value, default: 0] += 1
      }
      distribution = distribution.mapValues({ $0 / Double(samples.count) })
      
      variableValues[variable] = distribution
    }
    return variableValues
  }
  
  public var variableValuesUsingWP: [SourceVariable: [VariableValue: ClosedRange<Double>]] {
    if samples.isEmpty {
      return [:]
    }
    var variableValues: [SourceVariable: [VariableValue: ClosedRange<Double>]] = [:]
    for variable in samples.first!.values.keys {
      let queryVar = SourceVariable(name: "$query", disambiguationIndex: 0, type: .int)
      let inferenceResult = HistoryInferenceEngine.infer(history: augmentedExecutionHistory, loopIterationBounds: loopIterationBounds, f: .probability(of: variable, equalTo: .variable(queryVar)))
      
      let lowerBoundPlaceholderTerm = (inferenceResult.wpf / inferenceResult.wlp1)
      let upperBoundPlaceholderTerm = ((inferenceResult.wpf + .number(1) - inferenceResult.woip1) ./. (inferenceResult.wlp1 - inferenceResult.wlp0))
      
      let possibleValues = Set(samples.map({ $0.values[variable]! }))

      var distribution: [VariableValue: ClosedRange<Double>] = [:]
      for value in possibleValues {
        let lowerBoundTerm = lowerBoundPlaceholderTerm.replacing(variable: queryVar, with: Term(value)) ?? lowerBoundPlaceholderTerm
        let upperBoundTerm = upperBoundPlaceholderTerm.replacing(variable: queryVar, with: Term(value)) ?? lowerBoundTerm
        
        distribution[value] = lowerBoundTerm.doubleValue...upperBoundTerm.doubleValue
      }
      variableValues[variable] = distribution
    }
    return variableValues
  }
  
  public init(sourceCode: String, numSamples: Int) throws {
    self.sourceCode = sourceCode
    self.numSamples = numSamples
    
    let parser = Parser(sourceCode: sourceCode)
    let rawAst = try parser.parseFile()
    ast = try TypeCheckPipeline.typeCheck(stmt: rawAst) as! TopLevelCodeStmt
    
    let executionResult = Executor.execute(stmt: ast, numSamples: numSamples)
    self.loopIterationBounds = executionResult.loopIterationBounds
    self.executionOutline = executionResult.executionOutline
  }
  
  public func stepOver() {
    self.executionHistory = executionHistory.appending(.stepOver)
  }
  
  public func stepIntoTrue() {
    self.executionHistory = executionHistory.appending(.stepIntoTrue)
  }
  
  public func stepIntoFalse() {
    self.executionHistory = executionHistory.appending(.stepIntoFalse)
  }
}
