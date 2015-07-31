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
      var commandBuffer = try ItunesSearchQuery.stripInvocation(commandArguments)
      (type, commandBuffer) = try ItunesSearchQuery.parseCommand(commandBuffer)
      (search, commandBuffer) = try ItunesSearchQuery.parseSearch(commandBuffer)
      file = try ItunesSearchQuery.parseFileArgument(commandBuffer)
    }catch{ throw error }
  }

  static func checkArgument(argument: String, allowed: [String]) -> Bool{
    return allowed.contains(argument.lowercaseString)
  }

  static func stripInvocation(arguments: [String]) throws -> [String]{
    guard let(_, tail) = arguments.decompose else{ throw ItunesSearchQueryError.noArguments }
    return tail
  }

  static func matchCommand(command: String) -> SearchType? {
    if checkArgument(command, allowed: ["-tv", "-television", "-t"]) { return .tv }
    if checkArgument(command, allowed: ["-movie", "-m"]) { return .movie }
    return nil
  }

  static func parseCommand (arguments: [String]) throws -> (SearchType, [String]){
    guard let(arg, tail) = arguments.decompose else{ throw ItunesSearchQueryError.badTypeQuery }
    guard let command = matchCommand(arg) else { throw ItunesSearchQueryError.badTypeQuery }
    return (command, tail)
  }

  static func parseSearch (arguments: [String]) throws -> (String, [String]){
    guard let (arg, _tail) = arguments.decompose else { throw ItunesSearchQueryError.badSearchTerm }
    let flags = ["-s", "-search"]
    guard checkArgument(arg, allowed: flags) else { throw ItunesSearchQueryError.badSearchTerm }
    guard let (search, tail) = _tail.decompose else { throw ItunesSearchQueryError.badSearchTerm }
    return (search, tail)
  }

  static func parseFileArgument(arguments: [String]) throws -> String {
    guard let (arg, tail) = arguments.decompose else { throw ItunesSearchQueryError.badFileArgment }
    let allowed = ["-o", "-out", "-outFile"]
    guard checkArgument(arg, allowed: allowed) else { throw ItunesSearchQueryError.badFileArgment }
    guard let file = tail.first else { throw ItunesSearchQueryError.badFileArgment }
    return file
  }

  var url: NSURL?{
    let urlString = "https://itunes.apple.com/search?term=\(search.itunesEncode)&" +
    "media=\(type.rawValue)&limit=10\(type.filterValues)"
    return NSURL(string: urlString)
  }
}
