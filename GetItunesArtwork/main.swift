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
  var decompose: (head: T, tail: [T])? {
    return (count > 0) ? (self[0], Array(self[1..<count])) : nil
  }
}

extension String{
  var itunesEncode: String{
    return self
  }
}

enum SearchType: String{
  case tv = "tvShow", movie = "movie"

  static func matchCommand(command: String) -> SearchType? {
    switch command.lowercaseString{
    case "-tv", "-television", "-t": return .tv
    case "-movie", "-m": return .movie
    default:return nil
    }
  }
}

struct ItunesSearchResult{
  let url: String
  let label: String

  init(url: String, label: String){
    self.url = url
    self.label = label
  }
}

let semaphore = dispatch_semaphore_create(0)

func performQuery(query: ItunesSearchQuery){
  guard let url = query.url else{
    print("Error generating url")
    return
  }
  let session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())

  if let task = session.dataTaskWithURL(url, completionHandler:queryCompletion) {
    task.resume()
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
  }
}

func queryCompletion(data: NSData?, response: NSURLResponse?, error: NSError?){
  if let _ = error {
    print("Error loading itunes data")
  }else if let data = data{
    parseResults(data)
  }
  dispatch_semaphore_signal(semaphore)
}

func parseResults(data: NSData){
  //Todo: parse results
  if let string = NSString(data: data, encoding: NSUTF8StringEncoding) {
    print(string)
  }
}

//Testing code only
if let query = ItunesSearchQuery(commandArguments: ["", "-tv", "-s", "test", "-o", "test.jpg"]){
  performQuery(query)
}

//if let query = ItunesSearchQuery(commandArguments: Process.arguments){
//  performQuery(query)
//}
