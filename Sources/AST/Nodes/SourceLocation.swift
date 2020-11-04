public struct SourceLocation: Comparable, CustomStringConvertible {
  /// The line of this position (1-based)
  public let line: Int
  
  /// The column of this position (1-based)
  public let column: Int
  
  /// The offset of this position in the source file in terms of *extended grapheme clusters* (the same notion that Swift strings use for subscripts)
  public let offset: String.Index
  
  public init(line: Int, column: Int, offset: String.Index) {
    self.line = line
    self.column = column
    self.offset = offset
  }
  
  public func advanced(in string: String) -> SourceLocation {
    let char = string[offset]
    let newOffset = string.index(after: offset)
    if char == "\n" {
      return SourceLocation(line: line + 1, column: 1, offset: newOffset)
    } else {
      return SourceLocation(line: line, column: column + 1, offset: newOffset)
    }
  }
  
  public static func <(lhs: SourceLocation, rhs: SourceLocation) -> Bool {
    let offsetBasedResult = (lhs.offset < rhs.offset)
#if DEBUG
    let lineColumnBasedResult: Bool
    if lhs.line < rhs.line {
      lineColumnBasedResult = true
    } else if lhs.line == rhs.line {
      lineColumnBasedResult = (lhs.column < rhs.column)
    } else {
      lineColumnBasedResult = false
    }
    assert(offsetBasedResult == lineColumnBasedResult)
#endif
    return offsetBasedResult
  }
  
  public var description: String {
    return "\(line):\(column)"
  }
}

public typealias SourceRange = Range<SourceLocation>
