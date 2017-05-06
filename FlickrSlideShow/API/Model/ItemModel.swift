//
//  ItemModel.swift
//  FlickrSlideShow
//
//  Created by taewan on 2017. 5. 3..
//  Copyright © 2017년 taewan. All rights reserved.
//

import Foundation
import AlamofireRSSParser

struct ItemModel: ObjectCollection {

    let title: String
    let link: String
    let media: String
    let mediaThumbnail: String
    
    init(_ rss: RSSItem) {
        self.title = rss.title ?? ""
        self.link = rss.link ?? ""
        self.media = rss.mediaContent ?? ""
        self.mediaThumbnail = rss.mediaThumbnail ?? ""
    }
}

extension ItemModel {
    enum SizeType: String {
        case thumbnail = "_s"
        case small = "_n"
        case medium = "_z"
        case base = "_b"
        
        static var types: [SizeType] {
            return [.base, .medium, .small, .thumbnail]
        }
    }
}


extension ItemModel {
    func mediaURL(by scaleType: SizeType) -> URL? {
        let urlString = self.media.replacingOccurrences(of: "_b", with: scaleType.rawValue)
        return URL(string : urlString)
    }
    
    func mediaSizeType(leftCount: Int, maxCount: Int = 10) -> ItemModel.SizeType {
        if leftCount < max(2, maxCount/5) {
            return .thumbnail
        } else if leftCount < max(2, maxCount/4) {
            return .small
        } else if leftCount < max(2, maxCount/3) {
            return .medium
        } else {
            return .base
        }
    }
}
