/// A command that is available in the debugger console and any of its subcommands
struct DebuggerCommand {
  /// A short description of what this command (and its subcommands) do.
  let description: String
  
  /// The action to execute when the command is invoked. If `nil`, the help text is shown.
  let action: ((_ arguments: [String]) throws -> Void)?
  
  /// Any subcommands of this command
  let subCommands: [[String]: DebuggerCommand]
  
  init(description: String, action: ((_ arguments: [String]) throws -> Void)? = nil, subCommands: [[String]: DebuggerCommand] = [:]) {
    let subCommandNames = subCommands.keys.flatMap({ $0 })
    assert(Set(subCommandNames).count == subCommandNames.count, "Some subcommand name is used twice")
    self.description = description
    self.action = action
    self.subCommands = subCommands
  }
  
  /// Print the help text for this command
  private func printHelp() {
    print(description)
    print()
    print("Available subcommands:")
    for (names, command) in subCommands {
      let description = command.description
      let firstHelpLine = description[..<(description.firstIndex(of: "\n") ?? description.endIndex)]
      print(" - \(names.joined(separator: ", ")): \(firstHelpLine)")
    }
  }
  
  /// Execute the action of this command or print the help text of this command if no action is specified.
  private func executeActionOrPrintHelp(arguments: [String]) throws {
    if let action = action {
      try action(arguments)
    } else {
      printHelp()
    }
  }
  
  /// Execute this comamnd (or one of its subcommands) with the given arguments.
  func execute(arguments: [String]) throws {
    guard let subCommandName = arguments.first else {
      // No more arguments that specify subcommands. Invoke this command with no more arguments
      try executeActionOrPrintHelp(arguments: [])
      return
    }
    // Print the help text if requested
    if subCommandName == "help" || subCommandName == "?" {
      printHelp()
      return
    }
    
    // Check if we have a subcommand that matches the name. If yes, execute it
    for (names, command) in subCommands {
      if names.contains(subCommandName) {
        try command.execute(arguments: Array(arguments.dropFirst()))
        return
      }
    }
    
    // Execute the current command with the given arguments
    try executeActionOrPrintHelp(arguments: arguments)
  }
}
