//
//  DebuggerView.swift
//  GUI
//
//  Created by Alex Hoppen on 05.11.20.
//

import AST
import ExecutionHistory

import AppKit
import Combine
import SwiftUI

fileprivate struct DebuggerButtonsView: View {
  let debugger: Debugger
  
  var body: some View {
    HStack() {
      Button("⤼") {
        debugger.stepOver()
      }
      Button("↓✓") {
        debugger.stepIntoTrue()
      }
      Button("↓✗") {
        debugger.stepIntoFalse()
      }
    }
    .buttonStyle(BorderlessButtonStyle())
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

struct DebuggerView: View {
  let debugger: Debugger
  @State var sourceLocation: SourceLocation?
  @State var variableValues: [SourceVariable: [VariableValue: ClosedRange<Double>]] = [:]
  @State var executionOutline: [ExecutionOutlineNode] = []
  @State var loopIterationBounds: LoopIterationBounds = [:]
  
  var body: some View {
    HStack {
      ExecutionOutlineView(sourceCode: debugger.sourceCode, ast: debugger.ast, initialSampleCount: debugger.numSamples, executionOutline: $executionOutline, loopIterationBounds: $loopIterationBounds, selectionCallback: { (node) in
        if let node = node {
          debugger.setExecutionHistory(node.executionHistory)
        } else {
          debugger.setExecutionHistory([])
        }
      })
      VStack {
        SourceCodeView(sourceCode: debugger.sourceCode, sourceLocation: $sourceLocation)
        DebuggerButtonsView(debugger: debugger)
        VariablesView(variableValues: $variableValues)
      }
    }.onReceive(debugger.sourceLocationPublisher) {
      self.sourceLocation = $0
    }
    .onReceive(debugger.variableValuesUsingWPPublisher) {
      self.variableValues = $0
    }
    .onReceive(debugger.executionOutlinePublisher) {
      self.executionOutline = $0
    }
    .onReceive(debugger.loopIterationBoundsPublisher) {
      self.loopIterationBounds = $0
    }
  }
}


struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    let debugger = try! Debugger(sourceCode: """
      int x = 5
      int y = 2
      int z = x + y
      int a = 1
      """, numSamples: 5)
    return DebuggerView(debugger: debugger)
  }
}
