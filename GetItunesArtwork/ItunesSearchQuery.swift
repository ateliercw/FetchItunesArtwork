//
//  ItunesSearchQuery.swift
//  GetItunesArtwork
//
//  Created by Michael Skiba on 7/21/15.
//  Copyright © 2015 AtelierClockwork. All rights reserved.
//

import Foundation

struct ItunesSearchQuery{
  let type: SearchType
  let search: String
  let file: String

  init?(commandArguments: [String]){
    guard let cleanResults = ItunesSearchQuery.stripInvocation(commandArguments) else{
      print("This script requires arguments to do anything useful")
      return nil
    }
    guard let (type, searchArguments) = ItunesSearchQuery.parseCommand(cleanResults) else{
      print("The script requires '-tv' or '-movie' as the first argument")
      return nil
    }
    self.type = type
    guard let (search, fileArguments) = ItunesSearchQuery.parseSearch(searchArguments) else{
      print("The script requires '-s \"search string\" as the second argument")
      return nil
    }
    self.search = search
    guard let file = ItunesSearchQuery.parseFileArgument(fileArguments) else{
      print("The script requires '-o \"outfile.jpg\" as the final argument")
      return nil
    }
    self.file = file
  }

  static func stripInvocation(arguments: [String]) -> [String]?{
    if let(_, tail) = arguments.decompose{
      return tail
    }
    return nil
  }

  static func parseCommand (arguments: [String]) -> (SearchType, [String])?{
    if let(searchString, tail) = arguments.decompose,
      command = SearchType.matchCommand(searchString){
        return (command, tail)
    }
    return nil
  }

  static func parseSearch (arguments: [String]) -> (String, [String])?{
    if let (searchArgument, searchTail) = arguments.decompose
      where ItunesSearchQuery.checkSearchArgument(searchArgument) {
        return searchTail.decompose
    }
    return nil
  }

  static func checkSearchArgument(argument: String) -> Bool{
    switch argument.lowercaseString{
    case "-s", "-search": return true
    default: return false
    }
  }

  static func parseFileArgument(arguments: [String]) -> String? {
    if let (fileArgument, fileTail) = arguments.decompose
      where ItunesSearchQuery.checkFileArgument(fileArgument) {
        return fileTail.first
    }
    return nil
  }

  static func checkFileArgument(argument: String) -> Bool{
    switch argument.lowercaseString{
    case "-o", "-out", "-outFile": return true
    default: return false
    }
  }

  var url: NSURL?{
    let urlString = "https://itunes.apple.com/search?term=\(search)&media=\(type.rawValue)&limit=10"
    return NSURL(string: urlString)
  }
}
