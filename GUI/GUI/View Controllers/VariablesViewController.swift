//
//  VariablesViewController.swift
//  GUI
//
//  Created by Alex Hoppen on 10.11.20.
//

import Cocoa
import SwiftUI

import AST
import ExecutionHistory

extension VariableValue {
  fileprivate var synthesizedDoubleValue: Double {
    switch self {
    case .integer(let value):
      return Double(value)
    case .float(let value):
      return value
    case .bool(let value):
      return value ? 1 : 0
    }
  }
  
  fileprivate var description: String {
    switch self {
    case .integer(let value):
      return value.description
    case .float(let value):
      return value.description
    case .bool(let value):
      return value.description
    }
  }
}

internal class VariablesViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
  @IBOutlet private var tableView: NSTableView!
  
  var variableValues: [SourceVariable: [VariableValue: ClosedRange<Double>]] {
    didSet {
      self.tableView.reloadData()
    }
  }
  
  init(variableValues: [SourceVariable: [VariableValue: ClosedRange<Double>]]) {
    self.variableValues = variableValues
    super.init(nibName: "VariablesViewController", bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.tableView.dataSource = self
    self.tableView.delegate = self
  }
  
  func numberOfRows(in tableView: NSTableView) -> Int {
    return variableValues.count
  }
  
  func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
    let variableName = variableValues.keys.sorted()[row]
    let values = variableValues[variableName]!
    
    switch tableColumn?.identifier.rawValue {
    case "variable":
      let textView = NSTextField(labelWithString: variableName.name)
      textView.font = NSFontManager().convert(textView.font!, toHaveTrait: .boldFontMask)
      return textView
    case "average":
      let average = values.map({ (value, proability) -> Double in
        value.synthesizedDoubleValue * proability.lowerBound
      }).reduce(0, +)
      return NSTextField(labelWithString: "\(average.rounded(decimalPlaces: 4))")
    case "value":
      let values = values.map({ (value, probability) -> String in
        if probability.upperBound - probability.lowerBound < 0.0001 {
          return "\(value.description): \((probability.lowerBound * 100).rounded(decimalPlaces: 2))%"
        } else {
          return "\(value.description): \((probability.lowerBound * 100).rounded(decimalPlaces: 2))% – \((probability.upperBound * 100).rounded(decimalPlaces: 2))%"
        }
      }).joined(separator: ", ")
      let textView = NSTextField(labelWithString: values)
      return textView
    default:
      fatalError("Unknown column")
    }
  }
}

struct VariablesView: NSViewControllerRepresentable {
  @Binding private var variableValues: [SourceVariable: [VariableValue: ClosedRange<Double>]]
  
  init(variableValues: Binding<[SourceVariable: [VariableValue: ClosedRange<Double>]]>) {
    self._variableValues = variableValues
  }
  
  func makeNSViewController(context: Context) -> VariablesViewController {
    return VariablesViewController(variableValues: self.variableValues)
  }
  
  func updateNSViewController(_ variablesViewController: VariablesViewController, context: Context) {
    variablesViewController.variableValues = variableValues
  }
}
