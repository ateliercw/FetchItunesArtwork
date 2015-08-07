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

enum ItunesSearchErrors: ErrorType{
  case badUrl(String), noResults
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

  func performQuery(completionHandler: (NSData?, NSURLResponse?, NSError?) -> Void) throws{
    let url = try self.url()
    let config = NSURLSessionConfiguration.defaultSessionConfiguration()
    let session = NSURLSession(configuration: config)
    session.dataTaskWithURL(url, completionHandler:completionHandler).resume()
  }

  func parseResults(data: NSData) throws -> ItunesResponse {
    do {
      let jsonOptions = NSJSONReadingOptions.AllowFragments
      let json = try NSJSONSerialization.JSONObjectWithData(data, options: jsonOptions)
      guard let results = json["results"] as? [NSDictionary] where results.count > 0 else {
        throw ItunesSearchErrors.noResults
      }
      return try ItunesResponse(mediaType: self.type, json: results)
    }
    catch{ throw error }
  }
}
