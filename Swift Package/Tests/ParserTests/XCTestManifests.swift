#if !canImport(ObjectiveC)
import XCTest

extension LexerTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__LexerTests = [
        ("testLexerError", testLexerError),
        ("testLexFloatLiteral", testLexFloatLiteral),
        ("testLexFloatLiteralWithTrailingDot", testLexFloatLiteralWithTrailingDot),
        ("testLexFloatLiteralWithTwoDots", testLexFloatLiteralWithTwoDots),
        ("testLexProbKeyword", testLexProbKeyword),
        ("testLexSingleToken", testLexSingleToken),
        ("testLexThreeTokens", testLexThreeTokens),
        ("testMultipleLines", testMultipleLines),
    ]
}

extension ParserTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__ParserTests = [
        ("testExprWithPrecedence", testExprWithPrecedence),
        ("testExprWithThreeTerms", testExprWithThreeTerms),
        ("testParenthesisAtEnd", testParenthesisAtEnd),
        ("testParenthesisAtStart", testParenthesisAtStart),
        ("testParseBoolConstant", testParseBoolConstant),
        ("testParseEmptyCodeBlock", testParseEmptyCodeBlock),
        ("testParseFileWithoutSemicolons", testParseFileWithoutSemicolons),
        ("testParseFileWithSemicolons", testParseFileWithSemicolons),
        ("testParseIfElseStmt", testParseIfElseStmt),
        ("testParseIfStmt", testParseIfStmt),
        ("testParseIfStmtWithParanthesInCondition", testParseIfStmtWithParanthesInCondition),
        ("testParseObserveWithoutParan", testParseObserveWithoutParan),
        ("testParseObserveWithParan", testParseObserveWithParan),
        ("testParseProbStmtWithElseBody", testParseProbStmtWithElseBody),
        ("testParseProbStmtWithoutElseBody", testParseProbStmtWithoutElseBody),
        ("testParseVariableDeclaration", testParseVariableDeclaration),
        ("testParseWhileStmt", testParseWhileStmt),
        ("testSimpleExpr", testSimpleExpr),
        ("testSingleIdentifier", testSingleIdentifier),
        ("testVariableAssignemnt", testVariableAssignemnt),
    ]
}

public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(LexerTests.__allTests__LexerTests),
        testCase(ParserTests.__allTests__ParserTests),
    ]
}
#endif
