//
//  FeedService.swift
//  FlickrSlideShow
//
//  Created by taewan on 2017. 5. 3..
//  Copyright © 2017년 taewan. All rights reserved.
//

import Foundation
import Alamofire
import AlamofireRSSParser
//https://www.flickr.com/services/api/flickr.photos.search.html

final class FeedService {
    private let maxRetryCount: Int = 2
    private var retryCount: Int = 0
    
    private var isLoading: Bool = false
    private var contentType: ContentType = .photos
    
    init(contentType: ContentType) {
        self.contentType = contentType
    }
    
    func load(_ completed: @escaping ([ItemModel])-> Void) {
        if maxRetryCount < retryCount || isLoading {
            print("이미 로드중이라구!!!")
            return
        }
        self.isLoading = true
        
        let pamras: Parameters = ["content_type": contentType.rawValue]
        
        Router.feeds(pamras)
            .asDataRequest()
            .responseRSS { [weak self] (response: DataResponse<RSSFeed>) in
                self?.isLoading = false
                switch response.result {
                case .failure(_):
                    self?.retryCount += 1
                    self?.load(completed)
                    
                case .success(let rss):
                    self?.retryCount = 0
                    let items: [ItemModel]  = ItemModel.collection(rss.items)
                    completed(items.filter { $0.media.isEmpty == false })
                }//switch
        }
    }
}

extension FeedService {
    enum ContentType: Int {
        case photos = 1
        case screenshots = 2
        case other = 3
    }
}
