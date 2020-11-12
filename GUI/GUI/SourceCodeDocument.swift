import Cocoa
import SwiftUI


class SourceCodeDocument: NSDocument {
  var sourceCode: String = ""
  
  override class var autosavesInPlace: Bool {
    return true
  }

  override func makeWindowControllers() {
    let contentView: NSView
    // Create the SwiftUI view that provides the window contents.
    do {
      let debugger = try Debugger(sourceCode: sourceCode, numSamples: 10_000)
      let debuggerView = DebuggerView(debugger: debugger)
      contentView = NSHostingView(rootView: debuggerView)
    } catch {
      let compilationErrorView = CompilationErrorView(errorMessage: error.localizedDescription)
      contentView = NSHostingView(rootView: compilationErrorView)
    }
      
    // Create the window and set the content view.
    let window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
      styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
      backing: .buffered, defer: false)
    window.isReleasedWhenClosed = false
    window.center()
    window.contentView = contentView
    let windowController = NSWindowController(window: window)
    self.addWindowController(windowController)
  }

  override func data(ofType typeName: String) throws -> Data {
    // Saving is not supported
    throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
  }

  override func read(from data: Data, ofType typeName: String) throws {
    self.sourceCode = String(data: data, encoding: .utf8)!
  }
}
