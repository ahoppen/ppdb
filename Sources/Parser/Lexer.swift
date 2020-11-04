import AST

internal class Lexer {
  /// The source code to be lexed
  private let sourceCode: String
  
  /// The position of the next character to be lexed
  private var location: SourceLocation
  
  /// The pointing after the last character in the source file.
  lazy internal var endLocation: SourceLocation = {
    var sourceLocation = SourceLocation(line: 1, column: 1, offset: sourceCode.startIndex)
    while sourceLocation.offset != sourceCode.endIndex {
      sourceLocation = sourceLocation.advanced(in: sourceCode)
    }
    return sourceLocation
  }()
  
  public init(sourceCode: String) {
    self.sourceCode = sourceCode
    self.location = SourceLocation(line: 1, column: 1, offset: sourceCode.startIndex)
  }
  
  // MARK: Consume characters
  
  /// Returns the current character and advances the position to the next character.
  /// If the end of the file has been reached, returns `nil`.
  private func consume() -> Character? {
    guard location.offset != sourceCode.endIndex else {
      return nil
    }
    let char = sourceCode[location.offset]
    location = location.advanced(in: sourceCode)
    return char
  }
  
  /// If the next character to be lexed matches the given condition, consume it and returns `true`.
  /// If the character does not match the condition, does nothing and returns `false`.
  /// If the end of the file has been reached, returns `false` and does not consume anything.
  private func consume(if condition: (Character) -> Bool) -> Bool {
    guard let char = peek() else {
      // Nothing to consume
      return false
    }
    if condition(char) {
      _ = consume()
      return true
    } else {
      return false
    }
  }
  
  /// Return the current character or `nil` if the end of the file has been reached.
  private func peek() -> Character? {
    guard location.offset != sourceCode.endIndex else {
      return nil
    }
    return sourceCode[location.offset]
  }
  
  /// Consumes all whitespace until the next non-whitespace character.
  private func consumeWhitespace() {
    while true {
      let whitespaceConsumed = consume(if: { $0.isWhitespace })
      if !whitespaceConsumed {
        break
      }
    }
  }
  
  // MARK: Lex single tokens
  
  /// Lexes the next token in the source file and returns it.
  /// If the end of the file has been reached, returns `nil`.
  internal func nextToken() throws -> Token? {
    consumeWhitespace()
    
    let start = location
    let char = consume()
    
    let content: TokenContent
    switch char {
    case nil:
      // Reached the end of the file
      return nil
    case "(":
      content = .leftParen
    case ")":
      content = .rightParen
    case "{":
      content = .leftBrace
    case "}":
      content = .rightBrace
    case "=":
      if consume(if: { $0 == "=" }) {
        content = .equalEqual
      } else {
        content = .equal
      }
    case ":":
      content = .colon
    case ",":
      content = .comma
    case ";":
      content = .semicolon
    case "<":
      content = .lessThan
    case "+":
      content = .plus
    case "-":
      content = .minus
    case let char? where char.isNumber:
      content = lexNumberLiteralContent(firstChar: char)
    case let char? where char.isLetter:
      content = lexIdentifierOrKeywordContents(firstChar: char)
    case let char? where char.isWhitespace:
      fatalError("This should have been consumed by consumeWhitespace before")
    default:
      throw CompilerError(location: start, message: "Unexpected character \(char!)")
    }
    
    let end = location
    
    return Token(content: content, range: start..<end)
  }
  
  /// Lexes the next token as an integer or float literal.
  /// Assumes that the current lexing character is a number.
  /// - Parameter firstChar: The first character of the integer/float literal which has already been consumed
  /// - Returns: The lexed number literal
  private func lexNumberLiteralContent(firstChar: Character) -> TokenContent {
    assert(firstChar.isNumber, "Lexing an integer literal that didn't start with a number")
    
    var consumedDot = false
    var stringContent = String(firstChar)
    while true {
      guard let char = peek() else {
        break
      }
      if char.isNumber {
        stringContent.append(consume()!)
      } else if char == "." && !consumedDot {
        stringContent.append(consume()!)
        consumedDot = true
      } else {
        break
      }
    }
    
    if consumedDot {
      // Parse a float literal
      assert(stringContent.allSatisfy({ $0.isNumber || $0 == "." }))
      let floatContent = Double(stringContent)!
      return .floatLiteral(value: floatContent)
    } else {
      // Parse an integer literal
      assert(stringContent.allSatisfy({ $0.isNumber }))
      let intContent = Int(stringContent)!
      return .integerLiteral(value: intContent)
    }
  }
  
  /// Lexes the next token as an identifier or keyword.
  /// Assumes that the current lexing character is a letter.
  /// - Parameter firstChar: The first character of the identifier/keyword which has already been consumed
  /// - Returns: The lexed keyword/identifier
  private func lexIdentifierOrKeywordContents(firstChar: Character) -> TokenContent {
    assert(firstChar.isLetter, "Lexing an identifier or keyword token that didn't start with a letter")
    
    var content = String(firstChar)
    while peek()?.isLetter == true {
      content.append(consume()!)
    }
    
    assert(content.allSatisfy({ $0.isLetter }))
    
    switch content {
    case "if":
      return .if
    case "else":
      return .else
    case "while":
      return .while
    case "prob":
      return .prob
    case "int":
      return .int
    case "bool":
      return .bool
    case "true":
      return .true
    case "false":
      return .false
    case "observe":
      return .observe
    default:
      return .identifier(name: content)
    }
  }
}
