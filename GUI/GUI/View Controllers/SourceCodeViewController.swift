//
//  SourceCodeViewController.swift
//  GUI
//
//  Created by Alex Hoppen on 10.11.20.
//

import Cocoa
import SwiftUI

import AST

internal class SourceCodeViewController: NSViewController {
  @IBOutlet private var sourceCodeView: NSTextView?
  
  private let sourceCode: String
  var sourceLocation: SourceLocation? {
    didSet {
      updateView()
    }
  }
  
  init(sourceCode: String, sourceLocation: SourceLocation?) {
    self.sourceCode = sourceCode
    self.sourceLocation = sourceLocation
    super.init(nibName: "SourceCodeViewController", bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("Not implemented")
  }
  
  override func viewDidLoad() {
    self.updateView()
  }
  
  private func updateView() {
    guard let sourceCodeView = sourceCodeView else {
      return
    }
    let lines = sourceCode.components(separatedBy: "\n").map({
      return NSMutableAttributedString.init(string: "\($0)\n", attributes: [
        .font: NSFont(name: "Menlo", size: 13)!
      ])
    })
    if let currentLine = sourceLocation?.line, (currentLine - 1) < lines.count {
      let line = lines[currentLine - 1]
      line.addAttribute(.backgroundColor, value: #colorLiteral(red: 0.8431372549, green: 0.9098039216, blue: 0.8549019608, alpha: 1) as NSColor, range: NSRange(location: 0, length: line.length))
    }

    let highlightedSourceCode = NSMutableAttributedString()
    for line in lines {
      highlightedSourceCode.append(line)
    }
    sourceCodeView.textStorage?.setAttributedString(highlightedSourceCode)
  }
}

struct SourceCodeView: NSViewControllerRepresentable {
  private let sourceCode: String
  @Binding private var sourceLocation: SourceLocation?
  
  init(sourceCode: String, sourceLocation: Binding<SourceLocation?>) {
    self.sourceCode = sourceCode
    self._sourceLocation = sourceLocation
  }
  
  func makeNSViewController(context: Context) -> SourceCodeViewController {
    return SourceCodeViewController(sourceCode: self.sourceCode, sourceLocation: sourceLocation)
  }
  
  func updateNSViewController(_ sourceCodeViewController: SourceCodeViewController, context: Context) {
    sourceCodeViewController.sourceLocation = sourceLocation
  }
}
