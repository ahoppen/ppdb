import Foundation

public extension Double {
  func rounded(decimalPlaces: Int) -> Double {
    let padding = pow(10, Double(decimalPlaces))
    return (self * padding).rounded() / padding
  }
}
