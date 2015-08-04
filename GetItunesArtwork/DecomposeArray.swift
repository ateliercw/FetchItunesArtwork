//
//  DecomposeArray.swift
//  GetItunesArtwork
//
//  Created by Michael Skiba on 8/2/15.
//  Copyright © 2015 AtelierClockwork. All rights reserved.
//

import Foundation

extension Array {
  var decompose: (head: Element, tail: [Element])? {
    return (count > 0) ? (self[0], Array(self[1..<count])) : nil
  }
}

extension CollectionType{
  func throwingMap<T>(@noescape transform: (Self.Generator.Element) throws -> T) rethrows -> [T]{
    var result: [T] = []
    for x in self {
      try result.append(transform(x))
    }
    return result
  }
}
