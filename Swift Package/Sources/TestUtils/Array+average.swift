public extension Array where Element: BinaryInteger {
  var average: Double {
    return self.reduce(0.0, { $0 + Double($1) }) / Double(self.count)
  }
}
