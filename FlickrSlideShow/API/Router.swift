//
//  Router.swift
//  FlickrSlideShow
//
//  Created by taewan on 2017. 5. 3..
//  Copyright © 2017년 taewan. All rights reserved.
//

import Foundation
import Alamofire


enum Router {
    
    static let baseURLString = "https://api.flickr.com"
    case feeds(Parameters?)
        
    var result: (path: String, parameters: Parameters?) {
        switch self {
        case .feeds(let parameters):
            var parameters: Parameters = parameters ?? [:]
            parameters["format"] = "rss2"
            parameters["nojsoncallback"] = 1
            return ("/services/feeds/photos_public.gne", parameters)
        }
    }
    
    
}

extension Router: URLRequestConvertible {
    func asURLRequest() throws -> URLRequest {
        let url = try Router.baseURLString.asURL()
        let urlRequest = URLRequest(url: url.appendingPathComponent(result.path))
        return try URLEncoding.default.encode(urlRequest, with: result.parameters)
    }
    
    func asDataRequest() -> DataRequest {
        return Alamofire.request(self)
            
    }
}
