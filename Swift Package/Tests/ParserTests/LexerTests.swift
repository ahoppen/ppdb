@testable import Parser

import AST
import XCTest

fileprivate extension Lexer {
  /// Lex the entire file and return an array with its tokens
  func lexFile() throws -> [Token] {
    var tokens: [Token] = []
    
    while let token = try nextToken() {
      tokens.append(token)
    }
    
    return tokens
  }
}

fileprivate extension String {
  func index(atOffset offset: Int) -> String.Index {
    return self.index(self.startIndex, offsetBy: offset)
  }
}

class LexerTests: XCTestCase {
  func testLexSingleToken() {
    let sourceCode = "if"
    let lexer = Lexer(sourceCode: sourceCode)
    XCTAssertNoThrow(try {
      let tokens = try lexer.lexFile()
      XCTAssertEqual(tokens, [
        Token(
          content: .if,
          range: SourceLocation(line: 1, column: 1, offset: sourceCode.startIndex)..<SourceLocation(line: 1, column: 3, offset: sourceCode.endIndex)
          )
      ])
    }())
  }
  
  func testLexThreeTokens() {
    let sourceCode = "test = 37"
    let lexer = Lexer(sourceCode: sourceCode)
    XCTAssertNoThrow(try {
      let tokens = try lexer.lexFile()
      XCTAssertEqual(tokens, [
        Token(
          content: .identifier(name: "test"),
          range: SourceLocation(line: 1, column: 1, offset: sourceCode.startIndex)..<SourceLocation(line: 1, column: 5, offset: sourceCode.index(atOffset: 4))
        ),
        Token(
          content: .equal,
          range: SourceLocation(line: 1, column: 6, offset: sourceCode.index(atOffset: 5))..<SourceLocation(line: 1, column: 7, offset: sourceCode.index(atOffset: 6))
        ),
        Token(
          content: .integerLiteral(value: 37),
          range: SourceLocation(line: 1, column: 8, offset: sourceCode.index(atOffset: 7))..<SourceLocation(line: 1, column: 10, offset: sourceCode.index(atOffset: 9))
        ),
      ])
    }())
  }
  
  func testMultipleLines() {
    let sourceCode = """
    a b
    x y
    """
    let lexer = Lexer(sourceCode: sourceCode)
    XCTAssertNoThrow(try {
      let tokens = try lexer.lexFile()
      XCTAssertEqual(tokens, [
        Token(
          content: .identifier(name: "a"),
          range: SourceLocation(line: 1, column: 1, offset: sourceCode.startIndex)..<SourceLocation(line: 1, column: 2, offset: sourceCode.index(atOffset: 1))
        ),
        Token(
          content: .identifier(name: "b"),
          range: SourceLocation(line: 1, column: 3, offset: sourceCode.index(atOffset: 2))..<SourceLocation(line: 1, column: 4, offset: sourceCode.index(atOffset: 3))
        ),
        Token(
          content: .identifier(name: "x"),
          range: SourceLocation(line: 2, column: 1, offset: sourceCode.index(atOffset: 4))..<SourceLocation(line: 2, column: 2, offset: sourceCode.index(atOffset: 5))
        ),
        Token(
          content: .identifier(name: "y"),
          range: SourceLocation(line: 2, column: 3, offset: sourceCode.index(atOffset: 6))..<SourceLocation(line: 2, column: 4, offset: sourceCode.index(atOffset: 7))
        ),
      ])
    }())
  }
  
  func testLexerError() {
    let sourceCode = """
    a = 1 % 2
    """
    let lexer = Lexer(sourceCode: sourceCode)
    XCTAssertThrowsError(try lexer.lexFile()) { (error) in
      let parserError = error as? CompilerError
      XCTAssertNotNil(parserError)
      let errorPosition = SourceLocation(line: 1, column: 7, offset: sourceCode.index(atOffset: 6))
      XCTAssertEqual(parserError?.range, errorPosition..<errorPosition)
    }
  }
  
  func testLexFloatLiteral() {
    let sourceCode = "0.1"
    let lexer = Lexer(sourceCode: sourceCode)
    XCTAssertNoThrow(try {
      let tokens = try lexer.lexFile()
      XCTAssertEqual(tokens, [
        Token(
          content: .floatLiteral(value: 0.1),
          range: SourceLocation(line: 1, column: 1, offset: sourceCode.startIndex)..<SourceLocation(line: 1, column: 4, offset: sourceCode.index(atOffset: 3))
        )
      ])
    }())
  }
  
  func testLexFloatLiteralWithTrailingDot() {
    let sourceCode = "1."
    let lexer = Lexer(sourceCode: sourceCode)
    XCTAssertNoThrow(try {
      let tokens = try lexer.lexFile()
      XCTAssertEqual(tokens, [
        Token(
          content: .floatLiteral(value: 1),
          range: SourceLocation(line: 1, column: 1, offset: sourceCode.startIndex)..<SourceLocation(line: 1, column: 3, offset: sourceCode.index(atOffset: 2))
        )
      ])
    }())
  }
  
  func testLexFloatLiteralWithTwoDots() {
    let sourceCode = "1.2.3"
    let lexer = Lexer(sourceCode: sourceCode)
    XCTAssertThrowsError(try lexer.lexFile()) { (error) in
      let parserError = error as? CompilerError
      XCTAssertNotNil(parserError)
      let errorPosition = SourceLocation(line: 1, column: 4, offset: sourceCode.index(atOffset: 3))
      XCTAssertEqual(parserError?.range, errorPosition..<errorPosition)
    }
  }
  
  func testLexProbKeyword() {
    let sourceCode = "prob"
    let lexer = Lexer(sourceCode: sourceCode)
    XCTAssertNoThrow(try {
      let tokens = try lexer.lexFile()
      XCTAssertEqual(tokens, [
        Token(
          content: .prob,
          range: SourceLocation(line: 1, column: 1, offset: sourceCode.startIndex)..<SourceLocation(line: 1, column: 5, offset: sourceCode.index(atOffset: 4))
        )
      ])
    }())
  }
}
