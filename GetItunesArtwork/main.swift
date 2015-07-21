//
//  main.swift
//  GetItunesArtwork
//
//  Created by Michael Skiba on 7/20/15.
//  Copyright © 2015 AtelierClockwork. All rights reserved.
//

import Foundation

let args = Process.arguments

extension Array {
  var decompose : (head: T, tail: [T])? {
    return (count > 0) ? (self[0], Array(self[1..<count])) : nil
  }
}

enum SearchType{
  case tv, movie

  static func matchCommand(command: String) -> SearchType? {
    switch command.lowercaseString{
    case "-tv", "-television", "-t": return .tv
    case "-movie", "-m": return .movie
    default:return nil
    }
  }
}

if let query = ItunesSearchQuery(commandArguments: Process.arguments){
}
