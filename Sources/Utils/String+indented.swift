public extension String {
  /// Indent each line in the given string to the given indentaiton level
  func indented(_ level: Int = 1) -> String {
    // Split by newline, prepend indentaiton characters and join using newline again.
    return self.split(separator: "\n")
      .map({ String(repeating: "  ", count: level) + $0 })
      .joined(separator: "\n")
  }
}
