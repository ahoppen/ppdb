//
//  OutlineViewController.swift
//  GUI
//
//  Created by Alex Hoppen on 10.11.20.
//

import Cocoa
import SwiftUI

import AST
import ExecutionHistory
import WPInference

fileprivate class RefiningTextField: NSView {
  let textView: NSTextField
  
  init(label: String, queue: DispatchQueue = .global(qos: .default), refine: @escaping () -> String?) {
    self.textView = NSTextField(labelWithString: label)
    super.init(frame: self.textView.bounds)
    self.addSubview(self.textView)
    queue.async {
      if let newLabel = refine() {
        DispatchQueue.main.async {
          self.textView.stringValue = newLabel
        }
      }
    }
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

internal class ExecutionOutlineViewController: NSViewController, NSOutlineViewDelegate, NSOutlineViewDataSource {
  @IBOutlet private var outlineView: NSOutlineView!
  
  private let sourceCode: String
  private let ast: TopLevelCodeStmt
  private let initialSampleCount: Int
  private let selectionCallback: (ExecutionOutlineNode?) -> Void
  
  var executionOutline: [ExecutionOutlineNode] = [] {
    didSet {
      if executionOutline != oldValue {
        self.outlineView.reloadData()
      }
    }
  }
  var loopIterationBounds: LoopIterationBounds? {
    didSet {
      if loopIterationBounds != oldValue {
        self.outlineView.reloadData()
      }
    }
  }
  
  init(sourceCode: String, ast: TopLevelCodeStmt, initialSampleCount: Int, executionOutline: [ExecutionOutlineNode], selectionCallback: @escaping (ExecutionOutlineNode?) -> Void) {
    self.sourceCode = sourceCode
    self.ast = ast
    self.initialSampleCount = initialSampleCount
    self.executionOutline = executionOutline
    self.selectionCallback = selectionCallback
    super.init(nibName: "ExecutionOutlineViewController", bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.outlineView.delegate = self
    self.outlineView.dataSource = self
  }
  
  func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
    let node = item as! ExecutionOutlineNode?
    if let node = node {
      return node.children.count
    } else {
      return executionOutline.count
    }
  }
  
  func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
    let node = item as! ExecutionOutlineNode?
    if let node = node {
      return node.children[index]
    } else {
      return executionOutline[index]
    }
  }
  
  func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
    return self.outlineView(outlineView, numberOfChildrenOfItem: item) > 0
  }
  
  func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
    let node = item as! ExecutionOutlineNode
    switch tableColumn?.identifier.rawValue {
    case "code":
      let textField = NSTextField(labelWithString: node.label.description(sourceCode: sourceCode))
      switch node.label {
      case .sourceCode(_):
        textField.font = NSFontManager().convert(textField.font!, toHaveTrait: .boldFontMask)
      case .branch(_), .iteration(_), .end:
        textField.font = NSFontManager().convert(textField.font!, toHaveTrait: .italicFontMask)
      }
      return textField
    case "samples":
      let percentage = Double(node.samples.count) / Double(initialSampleCount) * 100
      return RefiningTextField(label: "\(percentage.rounded(decimalPlaces: 2))%") {
        guard let loopIterationBounds = self.loopIterationBounds else {
          return nil
        }
        guard let augmentedExecutionHistory = try? node.executionHistory.augmented(with: self.ast) else {
          return nil
        }
        let inferenceResult = HistoryInferenceEngine.infer(history: augmentedExecutionHistory, loopIterationBounds: loopIterationBounds, f: .number(1))
        let percentage = inferenceResult.wpf.doubleValue * 100
        return "\(percentage.rounded(decimalPlaces: 2))%"
      }
    default:
      fatalError()
    }
  }
  
  func outlineViewSelectionDidChange(_ notification: Notification) {
    if outlineView.selectedRow == -1 {
      selectionCallback(nil)
    } else {
      let outlineView = notification.object as! NSOutlineView
      let selectedNode = outlineView.item(atRow: outlineView.selectedRow) as! ExecutionOutlineNode
      selectionCallback(selectedNode)
    }
  }
}

struct ExecutionOutlineView: NSViewControllerRepresentable {
  private let sourceCode: String
  private let ast: TopLevelCodeStmt
  private let initialSampleCount: Int
  private let selectionCallback: (ExecutionOutlineNode?) -> Void
  @Binding private var executionOutline: [ExecutionOutlineNode]
  @Binding private var loopIterationBounds: LoopIterationBounds
  
  init(sourceCode: String, ast: TopLevelCodeStmt, initialSampleCount: Int, executionOutline: Binding<[ExecutionOutlineNode]>, loopIterationBounds: Binding<LoopIterationBounds>, selectionCallback: @escaping (ExecutionOutlineNode?) -> Void) {
    self.sourceCode = sourceCode
    self.ast = ast
    self.initialSampleCount = initialSampleCount
    self.selectionCallback = selectionCallback
    self._executionOutline = executionOutline
    self._loopIterationBounds = loopIterationBounds
  }
  
  func makeNSViewController(context: Context) -> ExecutionOutlineViewController {
    return ExecutionOutlineViewController(sourceCode: sourceCode, ast: ast, initialSampleCount: initialSampleCount, executionOutline: executionOutline, selectionCallback: selectionCallback)
  }
  
  func updateNSViewController(_ outlineViewController: ExecutionOutlineViewController, context: Context) {
    outlineViewController.executionOutline = executionOutline
    outlineViewController.loopIterationBounds = loopIterationBounds
  }
}
