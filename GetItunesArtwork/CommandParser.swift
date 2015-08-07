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

protocol ConsoleError{
  var consoleError: String{ get }
}

protocol CommandParsable{
  typealias Command
  typealias Argument
}

extension CommandParsable{
  typealias Parser = ([Argument]) throws -> (Command, [Argument])

  static func parseCommands(input: [Argument], parser: Parser) throws -> [Command] {
      guard let (_, main) = input.decompose else {
        throw CommandParserError<Command, Argument>.noArguments
      }
      return try consumeInput(main, parser:parser)
  }

  private static func consumeInput(input: [Argument], parser: Parser) throws -> [Command] {
      let (cmd, tail) = try parser(input)
      return tail.count > 0 ? try [cmd] + consumeInput(tail, parser:parser) : [cmd]
  }
}
