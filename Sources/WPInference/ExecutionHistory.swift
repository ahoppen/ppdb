import AST

public enum DebuggerCommand {
  case stepOver
  case stepIntoTrue
  case stepIntoFalse
}

public struct ExecutionHistory {
  public let history: [DebuggerCommand]
  
  public init(history: [DebuggerCommand]) {
    self.history = history
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
}

public struct AugmentedExecutionHistory {
  public let history: [(command: DebuggerCommand, stmt: Stmt)]
}

