//
//  CommandParser.swift
//  GetItunesArtwork
//
//  Created by Michael Skiba on 8/1/15.
//  Copyright © 2015 AtelierClockwork. All rights reserved.
//

import Foundation

enum CommandParserError<Command, Argument>: ErrorType {
  case badCommand(Argument)
  case noArguments
  case missingArgument
  case missingRequiredCommands
  case duplicateCommand(Command)
}

protocol CommandParsable{
  typealias Command
  typealias Argument

  static func parseArument(arguments: [Argument]) throws -> (Command, [Argument])
}

extension CommandParsable{
  static func parseCommands(input: [Argument]) throws -> [Command] {
    guard let (_, main) = input.decompose else {
      throw CommandParserError<Command, Argument>.noArguments
    }
    do {
      return try consumeInput(main)
    }catch{
      throw error
    }
  }

  private static func consumeInput(input: [Argument]) throws -> [Command] {
    do {
      let (cmd, tail) = try parseArument(input)
      if tail.count > 0 { return try [cmd] + consumeInput(tail) }
      return [cmd]
    }catch{
      throw error
    }
  }
}
