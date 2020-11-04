public extension Dictionary {
  static func merged(_ dictionaries: [Dictionary], uniquingKeysWith: (Value, Value) -> Value) -> Dictionary {
    var merged: Dictionary = [:]
    for dictionary in dictionaries {
      merged.merge(dictionary, uniquingKeysWith: uniquingKeysWith)
    }
    return merged
  }
}
