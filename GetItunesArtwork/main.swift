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
  var decompose: (head: Element, tail: [Element])? {
    return (count > 0) ? (self[0], Array(self[1..<count])) : nil
  }
}

enum SearchType: String{
  case tv = "tvShow", movie = "movie"

  var titleSearchKey: String {
    switch self{
    case .movie: return "trackName"
    case .tv: return "collectionName"
    }
  }

  var filterValues: String{
    switch self{
    case .movie: return "&entity=movie&attribute=movieTerm"
    case .tv: return "&entity=tvSeason&attribute=tvSeasonTerm"
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

extension ItunesSearchQuery{

  func performQuery(){
    guard let url = url else{
      print("Error generating url")
      return
    }

    let config = NSURLSessionConfiguration.defaultSessionConfiguration()
    let session = NSURLSession(configuration: config)

    session.dataTaskWithURL(url, completionHandler:queryCompletion).resume()

    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
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
    do {
      let json = try NSJSONSerialization.JSONObjectWithData(data,
        options: NSJSONReadingOptions.AllowFragments)
      if let results = json["results"] as? [AnyObject] where results.count > 0 {
        prepareResults(results)
      }else{
        print("No results found")
      }
    }
    catch{
      print("Error parsing JSON")
    }
  }

  func prepareResults(results: [AnyObject]){
    let output = results.flatMap{ result in
      return resultFromJSON(result)
    }
    presentOptions(output.sort{ (lhs, rhs) in
      return lhs.label.caseInsensitiveCompare(rhs.label) == NSComparisonResult.OrderedAscending
    })
  }

  func resultFromJSON(jsonResult: AnyObject) -> ItunesSearchResult? {
    guard let result = jsonResult as? [String:AnyObject] else {
      return nil
    }
    guard let title = result[self.type.titleSearchKey] as? String,
      let artworkUrl100 = result["artworkUrl100"] as? String  else {
        return nil
    }
    let artworkURL = artworkUrl100.stringByReplacingOccurrencesOfString("100x100",
      withString: "600x600")
    return ItunesSearchResult(url: artworkURL, label: title)
  }

  func presentOptions(results: [ItunesSearchResult]){
    for (idx, result) in results.enumerate() {
      print("\(idx) - \(result.label)")
    }
    print("Select a number to download, or hit <Enter> to quit.")
    guard let input = getLine(), let selection = Int(input)
      where selection >= 0 && selection < results.count else{
      print("closing")
      return
    }
    downloadResults(results[selection]);
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

  func downloadResults(result: ItunesSearchResult){
    print("downloading artwork for: \(result.label)")
    let task = NSTask();
    task.launchPath = "/usr/bin/curl"
    task.arguments = ["-o", file, result.url]
    task.launch()
    task.waitUntilExit()
  }
}

extension ItunesSearchQueryError{
  var consoleError: String{
    switch (self){
    case noArguments: return "arguments to do anything useful"
    case badTypeQuery: return "'-tv' or '-movie' as the first argument"
    case badSearchTerm: return "'-s \"search string\" as the second argument"
    case badFileArgment: return "'-o \"outfile.jpg\" as the final argument"
    }
  }
}

do {
  try ItunesSearchQuery(commandArguments: Process.arguments).performQuery()
}catch{
  if let itunesError = error as? ItunesSearchQueryError{
    print("This script requires \(itunesError.consoleError)");
  }
  else{
    print("Unhandled other error")
  }
}
