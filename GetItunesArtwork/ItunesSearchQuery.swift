//
//  ItunesSearchQuery.swift
//  GetItunesArtwork
//
//  Created by Michael Skiba on 7/21/15.
//  Copyright © 2015 AtelierClockwork. All rights reserved.
//

import Foundation

private extension NSCharacterSet{
  static var iTunesCharacterSet: NSCharacterSet{
    let safeChars: NSMutableCharacterSet = NSMutableCharacterSet(bitmapRepresentation:
      NSCharacterSet.alphanumericCharacterSet().bitmapRepresentation)
    safeChars.addCharactersInString(" .-_*")
    return safeChars
  }
}

private extension String{
  var itunesEncode: String{
    let itunesSet = NSCharacterSet.iTunesCharacterSet
    let escapedString = self.stringByAddingPercentEncodingWithAllowedCharacters(itunesSet) ?? ""
    return escapedString.stringByReplacingOccurrencesOfString(" ", withString: "+")
  }
}

enum ItunesSearchQueryError: ErrorType {
  case noArguments, badTypeQuery, badSearchTerm, badFileArgment
}

struct ItunesSearchQuery{
  let type: SearchType
  let search: String
  let file: String

  init(commandArguments: [String]) throws {
    do {
      let typeArguments = try ItunesSearchQuery.stripInvocation(commandArguments)
      let (type, searchArguments) = try ItunesSearchQuery.parseCommand(typeArguments)
      let (search, fileArguments) = try ItunesSearchQuery.parseSearch(searchArguments)
      let file = try ItunesSearchQuery.parseFileArgument(fileArguments)
      self.type = type
      self.search = search
      self.file = file
    }catch{
      throw error
    }
  }

  static func checkArgument(argument: String, allowed: [String]) -> Bool{
    return allowed.contains(argument.lowercaseString)
  }

  static func stripInvocation(arguments: [String]) throws -> [String]{
    if let(_, tail) = arguments.decompose{ return tail }
    throw ItunesSearchQueryError.noArguments
  }

  static func matchCommand(command: String) -> SearchType? {
    if checkArgument(command, allowed: ["-tv", "-television", "-t"]) { return .tv }
    if checkArgument(command, allowed: ["-movie", "-m"]) { return .movie }
    return nil
  }

  static func parseCommand (arguments: [String]) throws -> (SearchType, [String]){
    if let(searchString, tail) = arguments.decompose, command = matchCommand(searchString){
        return (command, tail)
    }
    throw ItunesSearchQueryError.badTypeQuery
  }

  static func parseSearch (arguments: [String]) throws -> (String, [String]){
    if let (searchArgument, searchTail) = arguments.decompose
      where ItunesSearchQuery.checkArgument(searchArgument, allowed: ["-s", "-search"]),
      let (searchString, tail) = searchTail.decompose {
        return (searchString, tail)
    }
    throw ItunesSearchQueryError.badSearchTerm
  }

  static func parseFileArgument(arguments: [String]) throws -> String {
    if let (fileArgument, fileTail) = arguments.decompose
      where ItunesSearchQuery.checkArgument(fileArgument, allowed: ["-o", "-out", "-outFile"]),
      let file = fileTail.first{
        return file
    }
    throw ItunesSearchQueryError.badFileArgment
  }

  var url: NSURL?{
    let urlString = "https://itunes.apple.com/search?term=\(search.itunesEncode)&" +
    "media=\(type.rawValue)&limit=10\(type.filterValues)"
    return NSURL(string: urlString)
  }
}
