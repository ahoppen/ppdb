import Foundation

public struct ConsoleError: LocalizedError {
  public let message: String
  
  public init(message: String) {
    self.message = message
  }
  
  public init(unrecognisedArguments: [String]) {
    self.message = "Unrecognised arguments: '\(unrecognisedArguments.joined(separator: " "))'"
  }
  
  public var errorDescription: String? {
    return message
  }
}
