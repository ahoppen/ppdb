import AST
import Execution
import ExecutionHistory
import Parser
import TypeChecker
import WPInference

import Combine
import Dispatch

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

public class Debugger: ObservableObject {
  // MARK: Static properties
  
  public let sourceCode: String
  public let ast: TopLevelCodeStmt
  public let numSamples: Int
  private let loopIterationBounds: LoopIterationBounds
  private let executionOutline: [ExecutionOutlineNode]
  
  // MARK: Dynamic properties
  
  @Published
  private var executionHistoryStack: [ExecutionHistory] = [[]]
  private var executionHistory: ExecutionHistory {
    get {
      return executionHistoryStack.last!
    }
    set {
      executionHistoryStack[executionHistoryStack.count - 1] = newValue
    }
  }
  
  private lazy var executionHistoryPublisher: AnyPublisher<ExecutionHistory, Never> = {
    $executionHistoryStack.map {
      $0.first!
    }
    .eraseToAnyPublisher()
  }()
  
  private lazy var augmentedExecutionHistoryPublisher: AnyPublisher<AugmentedExecutionHistory?, Never> = { [unowned self] in
    executionHistoryPublisher.map {
      try? $0.augmented(with: self.ast)
    }
    .eraseToAnyPublisher()
  }()
  
  public lazy var sourceLocationPublisher: AnyPublisher<SourceLocation?, Never> = {
    executionHistoryPublisher.map { [unowned self] in
      try? $0.appending(.stepOver).augmented(with: self.ast).history.last?.stmt.range.lowerBound
    }
    .eraseToAnyPublisher()
  }()
  
  public lazy var samplesPublisher: AnyPublisher<[Sample], Never> = {
    augmentedExecutionHistoryPublisher.map { [unowned self] (augmentedExecutionHistory) -> [Sample] in
      guard let augmentedExecutionHistory = augmentedExecutionHistory else {
        return []
      }
      return HistoryExecutor.execute(history: augmentedExecutionHistory, numSamples: self.numSamples)
    }
    .eraseToAnyPublisher()
  }()
  
  public lazy var sampledVariableValuesPublisher: AnyPublisher<[SourceVariable: [VariableValue: ClosedRange<Double>]], Never> = {
    samplesPublisher.map { (samples) -> [SourceVariable: [VariableValue: ClosedRange<Double>]] in
      if samples.isEmpty {
        return [:]
      }
      var variableValues: [SourceVariable: [VariableValue: ClosedRange<Double>]] = [:]
      for variable in samples.first!.values.keys {
        var distribution: [VariableValue: Double] = [:]
        
        for sample in samples {
          let value = sample.values[variable]!
          distribution[value, default: 0] += 1
        }
        distribution = distribution.mapValues({ $0 / Double(samples.count) })
        
        variableValues[variable] = distribution.mapValues({
          return $0...$0
        })
      }
      return variableValues
    }
    .eraseToAnyPublisher()
  }()
  
  public lazy var variableValuesUsingWPPublisher: AnyPublisher<[SourceVariable: [VariableValue: ClosedRange<Double>]], Never> = {
    Publishers.CombineLatest(augmentedExecutionHistoryPublisher, loopIterationBoundsPublisher)
      .receive(on: DispatchQueue.global(qos: .userInitiated))
      .map { (augmentedExecutionHistory, loopIterationBounds) -> [SourceVariable: [VariableValue: ClosedRange<Double>]] in
        guard let augmentedExecutionHistory = augmentedExecutionHistory else {
          return [:]
        }
        let samples = HistoryExecutor.execute(history: augmentedExecutionHistory, numSamples: self.numSamples)
        if samples.isEmpty {
          return [:]
        }
        var variableValues: [SourceVariable: [VariableValue: ClosedRange<Double>]] = [:]
        for variable in samples.first!.values.keys {
          let queryVar = SourceVariable(name: "$query", disambiguationIndex: 0, type: .int)
          let inferenceResult = HistoryInferenceEngine.infer(history: augmentedExecutionHistory, loopIterationBounds: loopIterationBounds, f: .probability(of: variable, equalTo: .variable(queryVar)))
          
          let lowerBoundPlaceholderTerm = inferenceResult.lowerBound
          let upperBoundPlaceholderTerm = inferenceResult.upperBound
          
          let possibleValues = Set(samples.map({ $0.values[variable]! }))
          
          var distribution: [VariableValue: ClosedRange<Double>] = [:]
          for value in possibleValues {
            let lowerBoundTerm = lowerBoundPlaceholderTerm.replacing(variable: queryVar, with: Term(value)) ?? lowerBoundPlaceholderTerm
            let upperBoundTerm = upperBoundPlaceholderTerm.replacing(variable: queryVar, with: Term(value)) ?? lowerBoundTerm
            
            if upperBoundTerm.doubleValue - lowerBoundTerm.doubleValue > 0.01 {
              fatalError("Difference between upper bound and lower bound is bigger than numerical instabilities should account for")
            }
            distribution[value] = lowerBoundTerm.doubleValue...max(lowerBoundTerm.doubleValue, upperBoundTerm.doubleValue)
          }
          variableValues[variable] = distribution
        }
        return variableValues
      }
      .receive(on: DispatchQueue.main)
      .eraseToAnyPublisher()
  }()
  
  public lazy var entireExecutionResult: AnyPublisher<(samples: [Sample], loopIterationBounds: LoopIterationBounds, executionOutline: [ExecutionOutlineNode]), Never> = {
    return Future<(samples: [Sample], loopIterationBounds: LoopIterationBounds, executionOutline: [ExecutionOutlineNode]), Never> { promise in
      DispatchQueue.global().async {
        let executionResult = Executor.execute(stmt: self.ast, numSamples: self.numSamples)
        DispatchQueue.main.async {
          promise(.success(executionResult))
        }
      }
    }
    .eraseToAnyPublisher()
  }()
  
  public lazy var executionOutlinePublisher: AnyPublisher<[ExecutionOutlineNode], Never> = {
    entireExecutionResult.map {
      $0.executionOutline
    }
    .eraseToAnyPublisher()
  }()
  
  public lazy var loopIterationBoundsPublisher: AnyPublisher<LoopIterationBounds, Never> = {
    entireExecutionResult.map {
      $0.loopIterationBounds
    }
    .eraseToAnyPublisher()
  }()
  
  // MARK: Methods
  
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
  
  public func saveState() {
    self.executionHistoryStack.append(self.executionHistoryStack.last!)
  }
  
  public func restoreState() {
    _ = self.executionHistoryStack.popLast()
  }
  
  public func setExecutionHistory(_ executionHistory: ExecutionHistory) {
    self.executionHistoryStack = [executionHistory]
  }
}
