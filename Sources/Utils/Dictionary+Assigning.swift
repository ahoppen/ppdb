//
//  Dictionary+Assigning.swift
//  
//
//  Created by Alex Hoppen on 04.11.20.
//

public extension Dictionary {
  /// Create a new dictionary by changing the value of the given key.
  func assiging(key: Key, value: Value) -> Self {
    var newDict = self
    newDict[key] = value
    return newDict
  }
}
