//
//  main.swift
//  GetItunesArtwork
//
//  Created by Michael Skiba on 7/20/15.
//  Copyright © 2015 AtelierClockwork. All rights reserved.
//

import Foundation

enum ItunesSearchCommands: CustomStringConvertible{
  case type(SearchType), search(String), file(String)

  var description: String{
    switch self{
    case .file(_): return "-file, -f, -outfile, or -o"
    case .search(_): return "-search or -s"
    case .type(_): return "-tv, -t, -movie, or -m"
    }
  }
}

extension ItunesSearchQuery: CommandParsable{
  typealias Argument = String
  typealias Command = ItunesSearchCommands
  typealias CommandError = CommandParserError<Command, Argument>

  static func parseArument(arguments: [Argument]) throws -> (Command, [Argument]) {
    guard let (argument, tail) = arguments.decompose else { throw CommandError.noArguments }
    switch argument.lowercaseString {
    case "-tv", "-t": return (ItunesSearchCommands.type(SearchType.tv), tail)
    case "-movie", "-m": return (ItunesSearchCommands.type(SearchType.movie), tail)
    case "-search", "-s":
      guard let (search, innerTail) = tail.decompose else { throw CommandError.missingArgument }
      return (ItunesSearchCommands.search(search), innerTail)
    case "-file", "-f", "-o", "-outfile":
      guard let (file, innerTail) = tail.decompose else { throw CommandError.missingArgument }
      return (ItunesSearchCommands.file(file), innerTail)
    default: throw CommandError.badCommand(argument)
    }
  }

  init(arguments: [Argument]) throws{
    let parser = ItunesSearchQuery.parseArument
    let commands = try ItunesSearchQuery.parseCommands(arguments, parser: parser)
    var type: SearchType?
    var file: String?
    var search: String?

    for cmd in commands{
      switch cmd{
      case .file(let fileIn):
        guard file == nil else { throw CommandError.duplicateCommand(cmd) }
        file = fileIn
      case .type(let typeIn):
        guard type == nil else { throw CommandError.duplicateCommand(cmd) }
        type = typeIn
      case .search(let searchIn):
        guard search == nil else { throw CommandError.duplicateCommand(cmd) }
        search = searchIn
      }
    }
    guard let finalType = type, finalSearch = search, finalFile = file else {
      throw CommandError.missingRequiredCommands
    }
    (self.type, self.search, self.file) = (finalType, finalSearch, finalFile)
  }
}

extension CommandParserError: ConsoleError{
  var consoleError: String{
    switch self{
    case .badCommand(let arg): return "\"\(arg)\" is not a valid command"
    case .noArguments: return "no arguments were supplied"
    case .missingArgument: return "missing argument"
    case .missingRequiredCommands: return "at least one required argument was not supplied"
    case .duplicateCommand(let cmd): return "\(cmd) should not be duplicated"
    }
  }
}

extension ItunesSearchResultError: ConsoleError{
  var consoleError: String{
    switch self{
    case .noArt: return "No artwork found in a node"
    case .noTitle: return "No titile found in a node"
    case .badResult: return "Cound not parse node"
    }
  }
}

extension ItunesSearchQuery{
  func downloadResults(result: ItunesSearchResult){
    print("downloading artwork for: \(result.label)")
    let task = NSTask();
    task.launchPath = "/usr/bin/curl"
    task.arguments = ["-o", file, result.url]
    task.launch()
    task.waitUntilExit()
  }
}

func getLine() -> String? {
  let keyboard = NSFileHandle.fileHandleWithStandardInput()
  guard let inputString = NSString(data: keyboard.availableData,
    encoding: NSUTF8StringEncoding) else{
      return nil
  }
  let set = NSCharacterSet.whitespaceAndNewlineCharacterSet()
  return inputString.stringByTrimmingCharactersInSet(set)
}

extension ItunesResponse{
  func presentOptions(completion: (ItunesSearchResult) -> Void ){
    for (idx, result) in results.enumerate() {
      print("\(idx) - \(result.label)")
    }
    print("Select a number to download, or hit <Enter> to quit.")
    guard let input = getLine(), let selection = Int(input)
      where selection >= 0 && selection < results.count else{
        print("closing")
        return
    }
    completion(results[selection]);
  }
}

typealias ItunesParserError = CommandParserError<ItunesSearchCommands, String>

do {
  let semaphore = dispatch_semaphore_create(0)
  let query = try ItunesSearchQuery(arguments: Process.arguments)
  var data: NSData?, error: NSError?
  try query.performQuery{ (bData: NSData?, _: NSURLResponse?, bError: NSError?) in
    (data, error) = (bData, bError)
    dispatch_semaphore_signal(semaphore)
  }
  dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
  if let error = error{
    throw error
  }
  guard let finalData = data else { throw ItunesSearchErrors.noResults }
  let response = try query.parseResults(finalData)
  response.presentOptions(query.downloadResults)
}catch{
  if let consoleError = error as? ConsoleError{
    print("\(consoleError.consoleError)");
  }else{
    let nserror = error as NSError
    print("\(nserror.localizedDescription)")
  }
}
