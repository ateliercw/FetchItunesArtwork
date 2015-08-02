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
    case .movie: return "entity=movie&attribute=movieTerm"
    case .tv: return "entity=tvSeason&attribute=tvSeasonTerm"
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

  static func sort(lhs: ItunesSearchResult, rhs: ItunesSearchResult) -> Bool{
      return lhs.label.caseInsensitiveCompare(rhs.label) == NSComparisonResult.OrderedAscending
  }
}

enum ItunesSearchErrors: ErrorType{
  case badUrl(String)
}

struct ItunesSearchQuery{
  let type: SearchType
  let search: String
  let file: String

  func url() throws -> NSURL{
    let baseURL = "https://itunes.apple.com/search"
    let term = "term=\(search.itunesEncode)"
    let media = "media=\(type.rawValue)"
    let urlString = "\(baseURL)?\(term)&\(media)&\(type.filterValues)&limit=10\(type.filterValues)"
    let maybeURL = NSURL(string: urlString)
    guard let url = maybeURL else { throw  ItunesSearchErrors.badUrl(urlString) }
    return url
  }
}

extension ItunesSearchQuery{

  func performQuery(completionHandler: (NSData?, NSURLResponse?, NSError?) -> Void) throws{
    do {
      let url = try self.url()
      let config = NSURLSessionConfiguration.defaultSessionConfiguration()
      let session = NSURLSession(configuration: config)
      session.dataTaskWithURL(url, completionHandler:completionHandler).resume()
    }catch{
      throw error
    }
  }

  func parseResults(data: NSData, resultHandler: ([ItunesSearchResult]) -> Void){
    do {
      let json = try NSJSONSerialization.JSONObjectWithData(data,
        options: NSJSONReadingOptions.AllowFragments)
      if let results = json["results"] as? [AnyObject] where results.count > 0 {
        prepareResults(results, resultHandler: resultHandler)
      }else{
        print("No results found")
      }
    }
    catch{
      print("Error parsing JSON")
    }
  }

  func prepareResults(results: [AnyObject], resultHandler: ([ItunesSearchResult]) -> Void){
    let output = results.flatMap{ result in
      return resultFromJSON(result)
    }
    resultHandler(output.sort(ItunesSearchResult.sort))
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

}
