//
//  ObjectSerializable.swift
//  FlickrSlideShow
//
//  Created by taewan on 2017. 5. 3..
//  Copyright © 2017년 taewan. All rights reserved.
//

import Foundation
import AlamofireRSSParser

public protocol ObjectSerializable {
    init(_ rss: RSSItem)
}

public protocol CollectionSerializable {
    static func collection<T: ObjectSerializable>(_ rss: [RSSItem]) -> [T]
}

public extension CollectionSerializable {
    static func collection<T: ObjectSerializable>(_ rss: [RSSItem]) -> [T] {
        return rss.map { T($0) }
    }
}

public typealias ObjectCollection = CollectionSerializable & ObjectSerializable
