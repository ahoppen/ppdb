public extension Sequence where Element: Equatable {
  var allEqual: Bool {
    guard let first = self.first(where: { _ in true }) else {
      return true
    }
    for element in self.dropFirst() {
      if element != first {
        return false
      }
    }
    return true
  }
}
