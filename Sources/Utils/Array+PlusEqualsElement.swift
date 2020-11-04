public extension Array {
  static func +=(_ lhs: inout Array<Element>, _ rhs: Element) {
    lhs = lhs + [rhs]
  }
}
