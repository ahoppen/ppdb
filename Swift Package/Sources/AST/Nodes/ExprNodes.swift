public protocol Expr: ASTNode {
  func accept<VisitorType: ASTVisitor>(_ visitor: VisitorType) -> VisitorType.ExprReturnType
  func accept<VisitorType: ASTVerifier>(_ visitor: VisitorType) throws -> VisitorType.ExprReturnType
}

// MARK: - Expression nodes

public enum BinaryOperator {
  case plus
  case minus
  case equal
  case lessThan
  
  /// Returns the precedence of the operator. A greater value means higher precedence.
  public var precedence: Int {
    switch self {
    case .plus, .minus:
      return 2
    case .equal, .lessThan:
      return 1
    }
  }
}

/// Application of a binary operator to two operands
public struct BinaryOperatorExpr: Expr {
  public let lhs: Expr
  public let rhs: Expr
  public let `operator`: BinaryOperator
  
  public let range: SourceRange
 
  public init(lhs: Expr, operator op: BinaryOperator, rhs: Expr, range: SourceRange) {
    self.lhs = lhs
    self.rhs = rhs
    self.operator = op
    self.range = range
  }
}

/// An interger literal
public struct IntegerLiteralExpr: Expr {
  public let value: Int
  public let range: SourceRange
  
  public init(value: Int, range: SourceRange) {
    self.value = value
    self.range = range
  }
}

/// An interger literal
public struct FloatLiteralExpr: Expr {
  public let value: Double
  public let range: SourceRange
  
  public init(value: Double, range: SourceRange) {
    self.value = value
    self.range = range
  }
}


public struct BoolLiteralExpr: Expr {
  public let value: Bool
  public let range: SourceRange
  
  public init(value: Bool, range: SourceRange) {
    self.value = value
    self.range = range
  }
}

/// A reference to a variable.
public struct VariableReferenceExpr: Expr {
  /// Before type checking (in particular variable resolving), `variable` is `.unresolved`, afterwards it is always `resolved`
  public let variable: UnresolvedVariable
  public let range: SourceRange
  
  public init(variable: UnresolvedVariable, range: SourceRange) {
    self.variable = variable
    self.range = range
  }
}

/// An expression inside paranthesis
public struct ParenExpr: Expr {
  public let subExpr: Expr
  public let range: SourceRange
  
  public init(subExpr: Expr, range: SourceRange) {
    self.subExpr = subExpr
    self.range = range
  }
}

// MARK: - Visitation


public extension BinaryOperatorExpr {
  func accept<VisitorType: ASTVisitor>(_ visitor: VisitorType) -> VisitorType.ExprReturnType {
    visitor.visit(self)
  }
  
  func accept<VisitorType: ASTVerifier>(_ visitor: VisitorType) throws -> VisitorType.ExprReturnType {
    try visitor.visit(self)
  }
  
  func accept<VisitorType: ASTRewriter>(_ visitor: VisitorType) throws -> Self {
    return try visitor.visit(self)
  }
}

public extension IntegerLiteralExpr {
  func accept<VisitorType: ASTVisitor>(_ visitor: VisitorType) -> VisitorType.ExprReturnType {
    visitor.visit(self)
  }
  
  func accept<VisitorType: ASTVerifier>(_ visitor: VisitorType) throws -> VisitorType.ExprReturnType {
    try visitor.visit(self)
  }
  
  func accept<VisitorType: ASTRewriter>(_ visitor: VisitorType) throws -> Self {
    return try visitor.visit(self)
  }
}

public extension FloatLiteralExpr {
  func accept<VisitorType: ASTVisitor>(_ visitor: VisitorType) -> VisitorType.ExprReturnType {
    visitor.visit(self)
  }
  
  func accept<VisitorType: ASTVerifier>(_ visitor: VisitorType) throws -> VisitorType.ExprReturnType {
    try visitor.visit(self)
  }
  
  func accept<VisitorType: ASTRewriter>(_ visitor: VisitorType) throws -> Self {
    return try visitor.visit(self)
  }
}

public extension BoolLiteralExpr {
  func accept<VisitorType: ASTVisitor>(_ visitor: VisitorType) -> VisitorType.ExprReturnType {
    visitor.visit(self)
  }
  
  func accept<VisitorType: ASTVerifier>(_ visitor: VisitorType) throws -> VisitorType.ExprReturnType {
    try visitor.visit(self)
  }
  
  func accept<VisitorType: ASTRewriter>(_ visitor: VisitorType) throws -> Self {
    return try visitor.visit(self)
  }
}

public extension VariableReferenceExpr {
  func accept<VisitorType: ASTVisitor>(_ visitor: VisitorType) -> VisitorType.ExprReturnType {
    visitor.visit(self)
  }
  
  func accept<VisitorType: ASTVerifier>(_ visitor: VisitorType) throws -> VisitorType.ExprReturnType {
    try visitor.visit(self)
  }
  
  func accept<VisitorType: ASTRewriter>(_ visitor: VisitorType) throws -> Self {
    return try visitor.visit(self)
  }
}

public extension ParenExpr {
  func accept<VisitorType: ASTVisitor>(_ visitor: VisitorType) -> VisitorType.ExprReturnType {
    visitor.visit(self)
  }
  
  func accept<VisitorType: ASTVerifier>(_ visitor: VisitorType) throws -> VisitorType.ExprReturnType {
    try visitor.visit(self)
  }
  
  func accept<VisitorType: ASTRewriter>(_ visitor: VisitorType) throws -> Self {
    return try visitor.visit(self)
  }
}

// MARK: - Equality ignoring ranges


public extension BinaryOperatorExpr {
  func equalsIgnoringRange(other: ASTNode) -> Bool {
    guard let other = other as? BinaryOperatorExpr else {
      return false
    }
    return self.operator == other.operator &&
      self.lhs.equalsIgnoringRange(other: other.lhs) &&
      self.rhs.equalsIgnoringRange(other: other.rhs)
  }
}

public extension IntegerLiteralExpr {
  func equalsIgnoringRange(other: ASTNode) -> Bool {
    guard let other = other as? IntegerLiteralExpr else {
      return false
    }
    return self.value == other.value
  }
}

public extension FloatLiteralExpr {
  func equalsIgnoringRange(other: ASTNode) -> Bool {
    guard let other = other as? FloatLiteralExpr else {
      return false
    }
    return self.value == other.value
  }
}

public extension BoolLiteralExpr {
  func equalsIgnoringRange(other: ASTNode) -> Bool {
    guard let other = other as? BoolLiteralExpr else {
      return false
    }
    return self.value == other.value
  }
}

public extension VariableReferenceExpr {
  func equalsIgnoringRange(other: ASTNode) -> Bool {
    guard let other = other as? VariableReferenceExpr else {
      return false
    }
    return self.variable.hasSameName(as: other.variable)
  }
}

public extension ParenExpr {
  func equalsIgnoringRange(other: ASTNode) -> Bool {
    guard let other = other as? ParenExpr else {
      return false
    }
    return self.subExpr.equalsIgnoringRange(other: other.subExpr)
  }
}
