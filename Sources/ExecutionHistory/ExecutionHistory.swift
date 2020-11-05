import AST

public enum DebuggerCommand: CustomStringConvertible {
  case stepOver
  case stepIntoTrue
  case stepIntoFalse
  
  public var description: String {
    switch self {
    case .stepOver:
      return "so"
    case .stepIntoTrue:
      return "sit"
    case .stepIntoFalse:
      return "sif"
    }
  }
}

public struct ExecutionHistory: ExpressibleByArrayLiteral, CustomStringConvertible {
  public let history: [DebuggerCommand]
  
  public init(arrayLiteral elements: DebuggerCommand...) {
    history = elements
  }
  
  public init(history: [DebuggerCommand]) {
    self.history = history
  }
  
  public var description: String {
    return history.description
  }
  
  public func augmented(with topLevelCode: TopLevelCodeStmt) -> AugmentedExecutionHistory {
    var remainingStatements = topLevelCode.stmts
    var augmentedHistory: [(DebuggerCommand, Stmt)] = []
    for debuggerCommand in history {
      let currentStatement = remainingStatements.removeFirst()
      
      augmentedHistory.append((debuggerCommand, currentStatement))
      switch (debuggerCommand, currentStatement) {
      case (.stepOver, _):
        break
      case (.stepIntoTrue, let ifStmt as IfStmt):
        // The if statements body's statements are now executed next
        remainingStatements.insert(contentsOf: ifStmt.ifBody.body, at: 0)
      case (.stepIntoTrue, let probStmt as ProbStmt):
        remainingStatements.insert(contentsOf: probStmt.ifBody.body, at: 0)
      case (.stepIntoTrue, let whileStmt as WhileStmt):
        // Add the while statement itself and the while body's statements.
        // We are thus essentially just shaving off one iteration and the while loop can be traversed again.
        remainingStatements.insert(whileStmt, at: 0)
        remainingStatements.insert(contentsOf: whileStmt.body.body, at: 0)
      case (.stepIntoTrue, _):
        break
        
      case (.stepIntoFalse, let ifStmt as IfStmt):
        remainingStatements.insert(contentsOf: ifStmt.elseBody?.body ?? [], at: 0)
      case (.stepIntoFalse, let probStmt as ProbStmt):
        remainingStatements.insert(contentsOf: probStmt.elseBody?.body ?? [], at: 0)
      case (.stepIntoFalse, _):
        break
      }
    }
    return AugmentedExecutionHistory(history: augmentedHistory)
  }
  
  public func appending(_ commands: [DebuggerCommand]) -> ExecutionHistory {
    return ExecutionHistory(history: history + commands)
  }
  
  public func appending(_ command: DebuggerCommand) -> ExecutionHistory {
    return self.appending([command])
  }
}

public struct AugmentedExecutionHistory {
  public let history: [(command: DebuggerCommand, stmt: Stmt)]
}

