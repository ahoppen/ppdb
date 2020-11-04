public protocol Stmt: ASTNode {
  func accept<VisitorType: ASTVisitor>(_ visitor: VisitorType) -> VisitorType.StmtReturnType
  func accept<VisitorType: ASTVerifier>(_ visitor: VisitorType) throws -> VisitorType.StmtReturnType
}

public enum Type: CustomStringConvertible, Equatable {
  case int
  case float
  case bool
  
  public var description: String {
    switch self {
    case .int:
      return "int"
    case .float:
      return "float"
    case .bool:
      return "bool"
    }
  }
}

/// A declaration of a new variable. E.g. `int x = y + 2`
public struct VariableDeclStmt: Stmt {
  /// The variable that's being declared
  public let variable: SourceVariable
  /// The expression that's assigned to the variable
  public let expr: Expr
  
  public let range: SourceRange
  
  public init(variable: SourceVariable, expr: Expr, range: SourceRange) {
    self.variable = variable
    self.expr = expr
    self.range = range
  }
}

/// An assignment to an already declared variable. E.g. `x = x + 1`
public struct AssignStmt: Stmt {
  /// The variable that's being assigned a value
  public let variable: UnresolvedVariable
  /// The expression that's assigned to the variable
  public let expr: Expr
  
  public let range: SourceRange
  
  public init(variable: UnresolvedVariable, expr: Expr, range: SourceRange) {
    self.variable = variable
    self.expr = expr
    self.range = range
  }
}

public struct ObserveStmt: Stmt {
  public let condition: Expr
  
  public let range: SourceRange
  
  public init(condition: Expr, range: SourceRange) {
    self.condition = condition
    self.range = range
  }
}

/// A code block that contains multiple statements inside braces.
public struct CodeBlockStmt: Stmt {
  public let body: [Stmt]
  
  public let range: SourceRange
  
  public init(body: [Stmt], range: SourceRange) {
    self.body = body
    self.range = range
  }
}

public struct IfStmt: Stmt {
  public let condition: Expr
  public let ifBody: CodeBlockStmt
  public let elseBody: CodeBlockStmt?
  
  public let range: SourceRange
  
  public init(condition: Expr, ifBody: CodeBlockStmt, elseBody: CodeBlockStmt?, range: SourceRange) {
    self.condition = condition
    self.ifBody = ifBody
    self.elseBody = elseBody
    self.range = range
  }
}

public struct ProbStmt: Stmt {
  public let condition: Expr
  public let ifBody: CodeBlockStmt
  public let elseBody: CodeBlockStmt?
  
  public let range: SourceRange
  
  public init(condition: Expr, ifBody: CodeBlockStmt, elseBody: CodeBlockStmt?, range: SourceRange) {
    self.condition = condition
    self.ifBody = ifBody
    self.elseBody = elseBody
    self.range = range
  }
}

public struct WhileStmt: Stmt {
  public let condition: Expr
  public let body: CodeBlockStmt
  
  public let range: SourceRange
  
  public init(condition: Expr, body: CodeBlockStmt, range: SourceRange) {
    self.condition = condition
    self.body = body
    self.range = range
  }
}

// MARK: - AST Visitation

public extension VariableDeclStmt {
  func accept<VisitorType: ASTVisitor>(_ visitor: VisitorType) -> VisitorType.StmtReturnType {
    visitor.visit(self)
  }
  
  func accept<VisitorType: ASTVerifier>(_ visitor: VisitorType) throws -> VisitorType.StmtReturnType {
    try visitor.visit(self)
  }
  
  func accept<VisitorType: ASTRewriter>(_ visitor: VisitorType) throws -> Self {
    return try visitor.visit(self)
  }
}

public extension AssignStmt {
  func accept<VisitorType: ASTVisitor>(_ visitor: VisitorType) -> VisitorType.StmtReturnType {
    visitor.visit(self)
  }
  
  func accept<VisitorType: ASTVerifier>(_ visitor: VisitorType) throws -> VisitorType.StmtReturnType {
    try visitor.visit(self)
  }
  
  func accept<VisitorType: ASTRewriter>(_ visitor: VisitorType) throws -> Self {
    return try visitor.visit(self)
  }
}

public extension ObserveStmt {
  func accept<VisitorType: ASTVisitor>(_ visitor: VisitorType) -> VisitorType.StmtReturnType {
    visitor.visit(self)
  }
  
  func accept<VisitorType: ASTVerifier>(_ visitor: VisitorType) throws -> VisitorType.StmtReturnType {
    try visitor.visit(self)
  }
  
  func accept<VisitorType: ASTRewriter>(_ visitor: VisitorType) throws -> Self {
    return try visitor.visit(self)
  }
}

public extension CodeBlockStmt {
  func accept<VisitorType: ASTVisitor>(_ visitor: VisitorType) -> VisitorType.StmtReturnType {
    visitor.visit(self)
  }
  
  func accept<VisitorType: ASTVerifier>(_ visitor: VisitorType) throws -> VisitorType.StmtReturnType {
    try visitor.visit(self)
  }
  
  func accept<VisitorType: ASTRewriter>(_ visitor: VisitorType) throws -> Self {
    return try visitor.visit(self)
  }
}

public extension IfStmt {
  func accept<VisitorType: ASTVisitor>(_ visitor: VisitorType) -> VisitorType.StmtReturnType {
    visitor.visit(self)
  }
  
  func accept<VisitorType: ASTVerifier>(_ visitor: VisitorType) throws -> VisitorType.StmtReturnType {
    try visitor.visit(self)
  }
  
  func accept<VisitorType: ASTRewriter>(_ visitor: VisitorType) throws -> Self {
    return try visitor.visit(self)
  }
}

public extension ProbStmt {
  func accept<VisitorType: ASTVisitor>(_ visitor: VisitorType) -> VisitorType.StmtReturnType {
    visitor.visit(self)
  }
  
  func accept<VisitorType: ASTVerifier>(_ visitor: VisitorType) throws -> VisitorType.StmtReturnType {
    try visitor.visit(self)
  }
  
  func accept<VisitorType: ASTRewriter>(_ visitor: VisitorType) throws -> Self {
    return try visitor.visit(self)
  }
}


public extension WhileStmt {
  func accept<VisitorType: ASTVisitor>(_ visitor: VisitorType) -> VisitorType.StmtReturnType {
    visitor.visit(self)
  }
  
  func accept<VisitorType: ASTVerifier>(_ visitor: VisitorType) throws -> VisitorType.StmtReturnType {
    try visitor.visit(self)
  }
  
  func accept<VisitorType: ASTRewriter>(_ visitor: VisitorType) throws -> Self {
    return try visitor.visit(self)
  }
}

// MARK: - Equality ignoring ranges

extension VariableDeclStmt {
  public func equalsIgnoringRange(other: ASTNode) -> Bool {
    guard let other = other as? VariableDeclStmt else {
      return false
    }
    return self.variable == other.variable &&
      self.expr.equalsIgnoringRange(other: other.expr)
  }
}

extension AssignStmt {
  public func equalsIgnoringRange(other: ASTNode) -> Bool {
    guard let other = other as? AssignStmt else {
      return false
    }
    return self.variable.hasSameName(as: other.variable) &&
      self.expr.equalsIgnoringRange(other: other.expr)
  }
}

extension ObserveStmt {
  public func equalsIgnoringRange(other: ASTNode) -> Bool {
    guard let other = other as? ObserveStmt else {
      return false
    }
    return self.condition.equalsIgnoringRange(other: other.condition)
  }
}

extension CodeBlockStmt {
  public func equalsIgnoringRange(other: ASTNode) -> Bool {
    guard let other = other as? CodeBlockStmt else {
      return false
    }
    if self.body.count != other.body.count {
      return false
    }
    return zip(self.body, other.body).allSatisfy({
      $0.0.equalsIgnoringRange(other: $0.1)
    })
  }
}

extension IfStmt {
  public func equalsIgnoringRange(other: ASTNode) -> Bool {
    guard let other = other as? IfStmt else {
      return false
    }
    
    let elseBodiesMatch: Bool
    switch (self.elseBody, other.elseBody) {
    case (nil, nil):
      elseBodiesMatch = true
    case (let selfElseBody?, let otherElseBody?):
      elseBodiesMatch = selfElseBody.equalsIgnoringRange(other: otherElseBody)
    default:
      elseBodiesMatch = false
    }
    
    return self.condition.equalsIgnoringRange(other: other.condition) &&
      self.ifBody.equalsIgnoringRange(other: other.ifBody) &&
      elseBodiesMatch
  }
}

extension ProbStmt {
  public func equalsIgnoringRange(other: ASTNode) -> Bool {
    guard let other = other as? ProbStmt else {
      return false
    }
    
    let elseBodiesMatch: Bool
    switch (self.elseBody, other.elseBody) {
    case (nil, nil):
      elseBodiesMatch = true
    case (let selfElseBody?, let otherElseBody?):
      elseBodiesMatch = selfElseBody.equalsIgnoringRange(other: otherElseBody)
    default:
      elseBodiesMatch = false
    }
    
    return self.condition.equalsIgnoringRange(other: other.condition) &&
      self.ifBody.equalsIgnoringRange(other: other.ifBody) &&
      elseBodiesMatch
  }
}

extension WhileStmt {
  public func equalsIgnoringRange(other: ASTNode) -> Bool {
    guard let other = other as? WhileStmt else {
      return false
    }
    return self.condition.equalsIgnoringRange(other: other.condition) &&
      self.body.equalsIgnoringRange(other: other.body)
  }
}
