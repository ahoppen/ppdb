import XCTest

import ASTTests
import DebuggerTests
import ExecutionHistoryTests
import ExecutionTests
import ParserTests
import TypeCheckerTests
import WPInferenceTests

var tests = [XCTestCaseEntry]()
tests += ASTTests.__allTests()
tests += DebuggerTests.__allTests()
tests += ExecutionHistoryTests.__allTests()
tests += ExecutionTests.__allTests()
tests += ParserTests.__allTests()
tests += TypeCheckerTests.__allTests()
tests += WPInferenceTests.__allTests()

XCTMain(tests)
