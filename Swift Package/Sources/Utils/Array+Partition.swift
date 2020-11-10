//
//  Array+Partition.swift
//  
//
//  Created by Alex Hoppen on 04.11.20.
//

public extension Array {
  /// Partition the array into two arrays based on the given `condition`.
  /// All elements that satisfy the condition are put into the `truePartition`, the rest into the `falsePartition`.
  func partition(by condition: (Element) -> Bool) -> (truePartition: Array, falsePartition: Array) {
    var truePartition = Array()
    var falsePartition = Array()
    for element in self {
      if condition(element) {
        truePartition.append(element)
      } else {
        falsePartition.append(element)
      }
    }
    return (truePartition, falsePartition)
  }
}
