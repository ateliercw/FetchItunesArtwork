//
//  ItunesResponse.swift
//  GetItunesArtwork
//
//  Created by Michael Skiba on 8/4/15.
//  Copyright © 2015 AtelierClockwork. All rights reserved.
//

import Foundation

enum ItunesSearchResultError: ErrorType {
  case badResult, noTitle, noArt
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

struct ItunesResponse{
  let mediaType: SearchType
  let results: [ItunesSearchResult]

  init(mediaType: SearchType, json: [NSDictionary]) throws {
    self.mediaType = mediaType
    self.results = try json.throwingMap{ jsonResult in
      guard let result = jsonResult as? [String:AnyObject] else {
        throw ItunesSearchResultError.badResult
      }
      guard let title = result[mediaType.titleSearchKey] as? String else{
        throw ItunesSearchResultError.noTitle
      }
      guard let artworkUrl100 = result["artworkUrl100"] as? String  else {
        throw ItunesSearchResultError.noArt
      }
      let artworkURL = artworkUrl100.stringByReplacingOccurrencesOfString("100x100",
        withString: "600x600")
      return ItunesSearchResult(url: artworkURL, label: title)
      }.sort(ItunesSearchResult.sort)
  }
}
