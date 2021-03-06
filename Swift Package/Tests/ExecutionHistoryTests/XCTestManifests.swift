#if !canImport(ObjectiveC)
import XCTest

extension ExecutionHistoryTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__ExecutionHistoryTests = [
        ("testGenerateAugmentedExecutionHistoryForLoop", testGenerateAugmentedExecutionHistoryForLoop),
        ("testGenerateAugmentedExecutionHistoryForSteppedIntoFalseProbStatement", testGenerateAugmentedExecutionHistoryForSteppedIntoFalseProbStatement),
        ("testGenerateAugmentedExecutionHistoryForSteppedIntoTrueProbStatement", testGenerateAugmentedExecutionHistoryForSteppedIntoTrueProbStatement),
        ("testGenerateAugmentedExecutionHistoryForSteppedOverProbStatement", testGenerateAugmentedExecutionHistoryForSteppedOverProbStatement),
        ("testGenerateAugmentedExecutionHistoryForStraightLineProgram", testGenerateAugmentedExecutionHistoryForStraightLineProgram),
    ]
}

public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(ExecutionHistoryTests.__allTests__ExecutionHistoryTests),
    ]
}
#endif
