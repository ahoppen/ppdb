import AST

fileprivate extension Token {
  var isOperator: Bool {
    return BinaryOperator(token: self.content) != nil
  }
  
  var isType: Bool {
    return Type(token: self.content) != nil
  }
}

fileprivate extension BinaryOperator {
  init?(token: TokenContent) {
    switch token {
    case .plus:
      self = .plus
    case .minus:
      self = .minus
    case .equalEqual:
      self = .equal
    case .lessThan:
      self = .lessThan
    default:
      return nil
    }
  }
}

fileprivate extension Type {
  init?(token: TokenContent) {
    switch token {
    case .int:
      self = .int
    case .bool:
      self = .bool
    default:
      return nil
    }
  }
}

public class Parser {
  private let lexer: Lexer
  
  private var peekedToken: Token?
  
  private var usedVariables: [SourceVariable] = []
  
  /// The ID of the next LoopId that has not been used yet.
  /// Use `unusedLoopId()` to generate a new `LoopId` and increment this index
  private var nextUnusedLoopId: Int = 0
  
  public init(sourceCode: String) {
    self.lexer = Lexer(sourceCode: sourceCode)
  }
  
  // MARK: - Variable management
  
  /// Create a new `SourceVariable` for a variable with the given name in the source code.
  /// If a variable with this name has already been declared, increase the `disambiguationIndex` to make it unique.
  func unusedVariable(name: String, type: Type) -> SourceVariable {
    let variable: SourceVariable
    var disambiguationIndex = 1
    while usedVariables.contains(where: { $0.name == name && $0.disambiguationIndex == disambiguationIndex }) {
      disambiguationIndex += 1
    }
    variable = SourceVariable(name: name, disambiguationIndex: disambiguationIndex, type: type)
    usedVariables.append(variable)
    return variable
  }
  
  func unusedLoopId() -> LoopId {
    defer {
      nextUnusedLoopId += 1
    }
    return LoopId(id: nextUnusedLoopId)
  }
  
  // MARK: - Parse the entire file
  
  public func parseFile() throws -> TopLevelCodeStmt {
    var stmts = [Stmt]()
    while true {
      guard let stmt = try parseStmt() else {
        break
      }
      stmts.append(stmt)
    }
    if stmts.isEmpty {
      throw CompilerError(location: lexer.endLocation, message: "Source file is empty")
    }
    return TopLevelCodeStmt(stmts: stmts, range: stmts.first!.range.lowerBound..<stmts.last!.range.upperBound)
  }
  
  // MARK: - Retrieving tokens
  
  /// Consume the next token and return it.
  @discardableResult
  private func consumeToken() throws -> Token? {
    if let peekedToken = peekedToken {
      let nextToken = peekedToken
      self.peekedToken = nil
      return nextToken
    } else {
      return try lexer.nextToken()
    }
  }
  
  /// Consume the next token if it matches the given condition.
  /// If the condition is not satisfied, throw a `ParserError` with the given error message.
  /// If the end of file is reached, returns a generic error message that the end of file was unexpectedly reached.
  @discardableResult
  private func consumeToken(condition: (TokenContent) -> Bool, errorMessage: String) throws -> Token {
    guard let token = try consumeToken() else {
      throw CompilerError(location: lexer.endLocation, message: "Unexpectedly reached end of file")
    }
    if !condition(token.content) {
      throw CompilerError(range: token.range, message: errorMessage)
    } else {
      return token
    }
  }
  
  /// Peek at the next token without consuming it
  private func peekToken() throws -> Token? {
    if let peekedToken = peekedToken {
      return peekedToken
    } else {
      peekedToken = try consumeToken()
      return peekedToken
    }
  }
  
  // MARK: - Parse statements
  
  /// Parse a statement.
  /// Returns the parsed statment or `nil` if the end of the file has been reached
  internal func parseStmt() throws -> Stmt? {
    let token = try peekToken()
    let stmt: Stmt?
    switch token?.content {
    case .int:
      stmt = try parseVariableDecl()
    case .bool:
      stmt = try parseVariableDecl()
    case .identifier:
      stmt = try parseAssignStmt()
    case .observe:
      stmt = try parseObserverStmt()
    case .if:
      stmt = try parseIfStmt()
    case .while:
      stmt = try parseWhileStmt()
    case .prob:
      stmt = try parseProbStmt()
    case .leftBrace:
      stmt = try parseCodeBlock()
    case nil:
      stmt = nil
    default:
      throw CompilerError(range: token!.range, message: "Expected start of statement")
    }
    // Consume any semicolons that are separating statements
    while try peekToken()?.content == .semicolon {
      try consumeToken()
    }
    return stmt
  }
  
  /// Parse a variable declaration of the form `int x = y + 2`.
  /// Assumes that the current token is a type.
  private func parseVariableDecl() throws -> VariableDeclStmt {
    let variableTypeToken = try consumeToken()!
    assert(variableTypeToken.isType)
    let type = Type(token: variableTypeToken.content)!
    
    let variableIdentifier = try consumeToken(condition: { $0.isIdentifier }, errorMessage: "Expected an identifier for the name of the variable declaration")
    guard case .identifier(let variableName) = variableIdentifier.content else {
      fatalError("The token we consumed was specified to be an identifier")
    }
    _ = try consumeToken(condition: { $0 == .equal }, errorMessage: "Expected '=' in variable declaration")
    
    let expr = try parseExpr()
    
    let variable = unusedVariable(name: variableName, type: type)
    return VariableDeclStmt(variable: variable, expr: expr, range: variableTypeToken.range.lowerBound..<expr.range.upperBound)
  }
  
  /// Parse an assignment to an already declared variable. E.g. `x = x + 1`
  /// Assumes that the next token is an identifier
  private func parseAssignStmt() throws -> AssignStmt {
    let variableIdentifier = try consumeToken()!
    assert(variableIdentifier.content.isIdentifier)
    guard case .identifier(let variableName) = variableIdentifier.content else {
      fatalError("The token we consumed was specified to be an identifier")
    }
    
    _ = try consumeToken(condition: { $0 == .equal }, errorMessage: "Expected '=' in variable assignment")
    
    let expr = try parseExpr()
    
    return AssignStmt(variable: .unresolved(name: variableName), expr: expr, range: variableIdentifier.range.lowerBound..<expr.range.upperBound)
  }
  
  private func parseIfStmt() throws -> Stmt {
    let ifToken = try consumeToken()!
    assert(ifToken.content == .if)
    
    let condition = try parseExpr()
    
    let ifBody = try parseCodeBlock()
    
    if try peekToken()?.content == .else {
      try consumeToken()
      let elseBody = try parseCodeBlock()
      return IfStmt(condition: condition, ifBody: ifBody, elseBody: elseBody, range: ifToken.range.lowerBound..<elseBody.range.upperBound)
    } else {
      return IfStmt(condition: condition, ifBody: ifBody, elseBody: nil, range: ifToken.range.lowerBound..<ifBody.range.upperBound)
    }
  }
  
  private func parseProbStmt() throws -> Stmt {
    let ifToken = try consumeToken()!
    assert(ifToken.content == .prob)
    
    let condition = try parseExpr()
    
    let ifBody = try parseCodeBlock()
    
    if try peekToken()?.content == .else {
      try consumeToken()
      let elseBody = try parseCodeBlock()
      return ProbStmt(condition: condition, ifBody: ifBody, elseBody: elseBody, range: ifToken.range.lowerBound..<elseBody.range.upperBound)
    } else {
      return ProbStmt(condition: condition, ifBody: ifBody, elseBody: nil, range: ifToken.range.lowerBound..<ifBody.range.upperBound)
    }
  }
  
  private func parseWhileStmt() throws -> WhileStmt {
    let whileToken = try consumeToken()!
    assert(whileToken.content == .while)
    
    let condition = try parseExpr()
    
    let body = try parseCodeBlock()
    
    return WhileStmt(condition: condition, body: body, loopId: unusedLoopId(), range: whileToken.range.lowerBound..<body.range.upperBound)
  }
  
  private func parseCodeBlock() throws -> CodeBlockStmt {
    let leftBrace = try consumeToken(condition: { $0 == .leftBrace }, errorMessage: "Expected '{' to start a code block")
    var stmts = [Stmt]()
    while let token = try peekToken(), token.content != .rightBrace {
      guard let stmt = try parseStmt() else {
        throw CompilerError(location: lexer.endLocation, message: "Reached end of file while inside a '{}' code block")
      }
      stmts.append(stmt)
    }
    guard let rightBrace = try consumeToken() else {
      throw CompilerError(location: lexer.endLocation, message: "Reached end of file while inside a '{}' code block")
    }
    assert(rightBrace.content == .rightBrace)
    
    return CodeBlockStmt(body: stmts, range: leftBrace.range.lowerBound..<rightBrace.range.upperBound)
  }
  
  private func parseObserverStmt() throws -> ObserveStmt {
    let observeToken = try consumeToken()!
    assert(observeToken.content == .observe)
    
    // We can parse the paranthesis of the obser
    let condition = try parseExpr()
    
    return ObserveStmt(condition: condition, range: observeToken.range.lowerBound..<observeToken.range.upperBound)
  }
  
  // MARK: - Parse expressions
  
  /// Parse an expression
  internal func parseExpr() throws -> Expr {
    return try parseExprImpl(precedenceHigherThan: 0)
  }
  
  /// Parse an expression up to the next binary operator that has a precedence lower than `precedenceHigherThan`.
  private func parseExprImpl(precedenceHigherThan: Int) throws -> Expr {
    var workingExpr = try parseBaseExpr()
    while true {
      let nextToken = try peekToken()
      if let nextToken = nextToken, nextToken.isOperator {
        let op = BinaryOperator(token: nextToken.content)!
        if op.precedence <= precedenceHigherThan {
          break
        }
        try consumeToken()
        let rhs = try parseExprImpl(precedenceHigherThan: op.precedence)
        workingExpr = BinaryOperatorExpr(lhs: workingExpr,
                                         operator: op,
                                         rhs: rhs,
                                         range: workingExpr.range.lowerBound..<rhs.range.upperBound)
      } else {
        break
      }
    }
    return workingExpr
  }
  
  /// Parse an expression without binary operators.
  private func parseBaseExpr() throws -> Expr {
    guard let nextToken = try consumeToken() else {
      throw CompilerError(location: lexer.endLocation, message: "Reached end of file while parsing expression")
    }
    switch nextToken.content {
    case .integerLiteral(let value):
      return IntegerLiteralExpr(value: value, range: nextToken.range)
    case .floatLiteral(let value):
      return FloatLiteralExpr(value: value, range: nextToken.range)
    case .true:
      return BoolLiteralExpr(value: true, range: nextToken.range)
    case .false:
      return BoolLiteralExpr(value: false, range: nextToken.range)
    case .identifier(name: let name):
      return VariableReferenceExpr(variable: .unresolved(name: name), range: nextToken.range)
    case .leftParen:
      let subExpr = try parseExpr()
      guard let rParen = try consumeToken() else {
        throw CompilerError(location: lexer.endLocation, message: "Expected ')' to close expression in paranthesis, but found end of file")
      }
      guard rParen.content == .rightParen else {
        throw CompilerError(range: rParen.range, message: "Expected ')' to close expression in paranthesis, but found '\(rParen.content)'")
      }
      return ParenExpr(subExpr: subExpr, range: nextToken.range.lowerBound..<rParen.range.upperBound)
    default:
      throw CompilerError(range: nextToken.range, message: "Expected an identifier or literal, found '\(nextToken)'.")
    }
  }
}
