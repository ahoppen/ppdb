import AST
import ExecutionHistory
import Utils

public enum Executor {
  public static func execute(stmt: Stmt, numSamples: Int) -> (samples: [Sample], loopIterationBounds: LoopIterationBounds, executionOutline: [ExecutionOutlineNode]) {
    let samples = Array(repeating: Sample.empty, count: numSamples)
    return Executor.execute(stmt: stmt, samples: samples, executionHistory: [])
  }
  
  private static func executeAtomicStmt(
    stmt: Stmt,
    samples: [Sample],
    executionHistory: ExecutionHistory,
    transformation: (Sample) -> Sample?
  ) -> (
    samples: [Sample],
    loopIterationBounds: LoopIterationBounds,
    executionOutline: [ExecutionOutlineNode]
  ) {
    let executionOutlineNode = ExecutionOutlineNode(
      children: [],
      position: stmt.range.lowerBound,
      label: .sourceCode(stmt.range),
      executionHistory: executionHistory,
      samples: samples
    )
    let newSamples = samples.compactMap(transformation)
    return (
      samples: newSamples,
      loopIterationBounds: [:],
      executionOutline: [executionOutlineNode]
    )
  }
  
  private static func executeMultipleStmts(
    stmts: [Stmt],
    enclosingStmt: Stmt,
    samples: [Sample],
    executionHistory: ExecutionHistory
  ) -> (
    samples: [Sample],
    loopIterationBounds: LoopIterationBounds,
    executionOutline: [ExecutionOutlineNode]
  ) {
    var newSamples = samples
    var loopIterationBounds: LoopIterationBounds = [:]
    var executionHistory = executionHistory
    
    var executionOutline: [ExecutionOutlineNode] = []
    
    for subStmt in stmts {
      let executionResult = Executor.execute(stmt: subStmt, samples: newSamples, executionHistory: executionHistory)
      loopIterationBounds = .merging(loopIterationBounds, executionResult.loopIterationBounds)
      newSamples = executionResult.samples
      executionOutline += executionResult.executionOutline
      executionHistory = executionHistory.appending(.stepOver)
    }
    executionOutline += ExecutionOutlineNode(
      children: [],
      position: enclosingStmt.range.upperBound,
      label: .end,
      executionHistory: executionHistory,
      samples: newSamples
    )
    return (
      samples: newSamples,
      loopIterationBounds:loopIterationBounds,
      executionOutline: executionOutline
    )
  }
  
  private static func executeIfStmt(
    ifStmt: Stmt,
    ifBody: Stmt,
    elseBody: Stmt?,
    samples: [Sample],
    executionHistory: ExecutionHistory,
    partition: (Sample) -> Bool
  ) -> (
    samples: [Sample],
    loopIterationBounds: LoopIterationBounds,
    executionOutline: [ExecutionOutlineNode]
  ) {
    let (trueSamples, falseSamples) = samples.partition(by: partition)
    let trueBranchExecutionResult = Executor.execute(stmt: ifBody, samples: trueSamples, executionHistory: executionHistory.appending(.stepIntoTrue))
    let trueBranchSamplesAfterStmt = trueBranchExecutionResult.samples
    var loopIterationBounds = trueBranchExecutionResult.loopIterationBounds
    let trueBranchExecutionOutlineNode = ExecutionOutlineNode(
      children: trueBranchExecutionResult.executionOutline,
      position: ifStmt.range.lowerBound,
      label: .branch(true),
      executionHistory: executionHistory.appending(.stepIntoTrue),
      samples: trueSamples
    )
    
    let falseBranchSamplesAfterStmt: [Sample]
    let falseBranchExecutionOutlineNode: ExecutionOutlineNode?
    if let elseBody = elseBody {
      let falseBranchExecutionResult = Executor.execute(stmt: elseBody, samples: falseSamples, executionHistory: executionHistory.appending(.stepIntoFalse))
      falseBranchSamplesAfterStmt = falseBranchExecutionResult.samples
      falseBranchExecutionOutlineNode = ExecutionOutlineNode(
        children: falseBranchExecutionResult.executionOutline,
        position: ifStmt.range.lowerBound,
        label: .branch(false),
        executionHistory: executionHistory.appending(.stepIntoFalse),
        samples: falseSamples
      )
      
      loopIterationBounds = .merging(loopIterationBounds, falseBranchExecutionResult.loopIterationBounds)
    } else {
      falseBranchSamplesAfterStmt = falseSamples
      falseBranchExecutionOutlineNode = nil
    }
    
    let executionOutlineNode = ExecutionOutlineNode(
      children: [trueBranchExecutionOutlineNode, falseBranchExecutionOutlineNode].compactMap({ $0 }),
      position: ifStmt.range.lowerBound,
      label: .sourceCode(ifStmt.range),
      executionHistory: executionHistory,
      samples: samples
    )
    
    return (
      samples: trueBranchSamplesAfterStmt + falseBranchSamplesAfterStmt,
      loopIterationBounds: loopIterationBounds,
      executionOutline: [executionOutlineNode]
    )
  }
  
  internal static func execute(
    stmt: Stmt,
    samples: [Sample],
    executionHistory: ExecutionHistory
  ) -> (
    samples: [Sample],
    loopIterationBounds: LoopIterationBounds,
    executionOutline: [ExecutionOutlineNode]
  ) {
    switch stmt {
    case let stmt as VariableDeclStmt:
      return executeAtomicStmt(stmt: stmt, samples: samples, executionHistory: executionHistory) { (sample) in
        let value = sample.evaluate(expr: stmt.expr)
        return sample.assigning(variable: stmt.variable, value: value)
      }
    case let stmt as AssignStmt:
      guard case .resolved(let variable) = stmt.variable else {
        fatalError("AST must be resolved to be executed")
      }
      return executeAtomicStmt(stmt: stmt, samples: samples, executionHistory: executionHistory) { (sample) in
        let value = sample.evaluate(expr: stmt.expr)
        return sample.assigning(variable: variable, value: value)
      }
    case let stmt as ObserveStmt:
      return executeAtomicStmt(stmt: stmt, samples: samples, executionHistory: executionHistory) { (sample) in
        if sample.evaluate(expr: stmt.condition).bool! {
          return sample
        } else {
          return nil
        }
      }
    case let stmt as CodeBlockStmt:
      return executeMultipleStmts(stmts: stmt.body, enclosingStmt: stmt, samples: samples, executionHistory: executionHistory)
    case let stmt as TopLevelCodeStmt:
      return executeMultipleStmts(stmts: stmt.stmts, enclosingStmt: stmt, samples: samples, executionHistory: executionHistory)
    case let stmt as IfStmt:
      return executeIfStmt(ifStmt: stmt, ifBody: stmt.ifBody, elseBody: stmt.elseBody, samples: samples, executionHistory: executionHistory) { (sample) -> Bool in
        return sample.evaluate(expr: stmt.condition).bool!
      }
    case let stmt as ProbStmt:
      return executeIfStmt(ifStmt: stmt, ifBody: stmt.ifBody, elseBody: stmt.elseBody, samples: samples, executionHistory: executionHistory) { (sample) -> Bool in
        let probability = sample.evaluate(expr: stmt.condition).float!
        return Double.random(in: 0..<1) < probability
      }
    case let stmt as WhileStmt:
      var liveSamples = samples
      var deadSamples: [Sample] = []
      var executionHistory = executionHistory
      var loopIterationBounds: LoopIterationBounds = [:]
      var iterationExecutionOutlineNodes: [ExecutionOutlineNode] = []
      
      // The first iteration of the executor performs the condition check and
      // only puts the samples that satisfy the condition in `liveSamples`.
      // Thus the only the second iteration of the below `repeat` loop evaluates
      // the first iteration of the `while` loop in the source code. Hence start
      // with an iteartion count of -1.
      var iterations = -1
      repeat {
        iterations += 1
        let (trueSamples, falseSamples) = liveSamples.partition(by: { $0.evaluate(expr: stmt.condition).bool! })
        executionHistory = executionHistory.appending(.stepIntoTrue)
        deadSamples += falseSamples
        liveSamples = trueSamples
        let executionResult = Executor.execute(stmt: stmt.body, samples: liveSamples, executionHistory: executionHistory)
        liveSamples = executionResult.samples
        loopIterationBounds = .merging(loopIterationBounds, executionResult.loopIterationBounds)
        iterationExecutionOutlineNodes += ExecutionOutlineNode(
          children: executionResult.executionOutline,
          position: stmt.range.lowerBound,
          label: .iteration(iterations + 1), // 1-based iteration count
          executionHistory: executionHistory,
          samples: liveSamples
        )
        // Add a step over command for each statment in the loop body
        executionHistory = executionHistory.appending(Array(repeating: DebuggerCommand.stepOver, count: stmt.body.body.count))
      } while !liveSamples.isEmpty
      loopIterationBounds = loopIterationBounds.setting(loopId: stmt.loopId, to: iterations)
      
      let outlineNode = ExecutionOutlineNode(
        children: iterationExecutionOutlineNodes,
        position: stmt.range.lowerBound,
        label: .sourceCode(stmt.range),
        executionHistory: executionHistory,
        samples: samples
      )
      
      return (
        samples: deadSamples,
        loopIterationBounds: loopIterationBounds,
        executionOutline: [outlineNode]
      )
    default:
      fatalError("Unknown Stmt type")
    }
  }
}
