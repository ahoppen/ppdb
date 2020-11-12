//
//  CompilationErrorView.swift
//  GUI
//
//  Created by Alex Hoppen on 12.11.20.
//

import SwiftUI

struct CompilationErrorView: View {
  let errorMessage: String
  
  var body: some View {
    VStack {
      Text("CompilationError")
        .font(.headline)
      Spacer()
        .frame(height: 10)
      Text(errorMessage)
    }
    .frame(width: 400, height: 200, alignment: .center)
  }
}

struct CompilationErrorView_Previews: PreviewProvider {
  static var previews: some View {
    CompilationErrorView(errorMessage: "1:1: Expected type")
  }
}
