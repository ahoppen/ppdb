import AST
import Utils

public struct ExecutionOutlineNode {
  public enum Label {
    case sourceCode(SourceRange)
    case branch(Bool)
    case iteration(Int)
    
    public func description(sourceCode: String) -> String {
      switch self {
      case .sourceCode(let range):
        return String(sourceCode.split(separator: "\n")[range.lowerBound.line - 1]).trimmingCharacters(in: .whitespaces)
      case .branch(let branch):
        return "\(branch)-Branch"
      case .iteration(let iteration):
        return "Iteration \(iteration)"
      }
    }
  }
  
  public let children: [ExecutionOutlineNode]
  public let position: SourceLocation
  public let label: Label
  public let executionHistory: ExecutionHistory
  public let samples: [Sample]
  
  public init(children: [ExecutionOutlineNode], position: SourceLocation, label: Label, executionHistory: ExecutionHistory, samples: [Sample]) {
    self.children = children
    self.position = position
    self.label = label
    self.executionHistory = executionHistory
    self.samples = samples
  }
  
  public func description(sourceCode: String) -> String {
    if children.isEmpty {
      return """
        ▷ \(label.description(sourceCode: sourceCode)) \(executionHistory)
        """
    } else {
      var descriptionPieces: [String] = []
      descriptionPieces += """
        ▽ \(label.description(sourceCode: sourceCode)) \(executionHistory)
        """
      for child in children {
        descriptionPieces += child.description(sourceCode: sourceCode).indented(1)
      }
      return descriptionPieces.joined(separator: "\n")
    }
  }
}
