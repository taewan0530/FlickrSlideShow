//
//  DataRequest+UIImage.swift
//  FlickrSlideShow
//
//  Created by taewan on 2017. 5. 5..
//  Copyright © 2017년 taewan. All rights reserved.
//

import Foundation
import Alamofire

/// A set of HTTP response status code that do not contain response data.
private let emptyDataStatusCodes: Set<Int> = [204, 205]

extension Request {
    /// Returns a result data type that contains the response data as-is.
    ///
    /// - parameter response: The response from the server.
    /// - parameter data:     The data returned from the server.
    /// - parameter error:    The error already encountered if it exists.
    ///
    /// - returns: The result data type.
    public static func serializeResponseImage(response: HTTPURLResponse?, data: Data?, error: Error?) -> Result<UIImage> {
        guard error == nil else { return .failure(error!) }
        
        if let response = response, emptyDataStatusCodes.contains(response.statusCode) { return .success(UIImage()) }
        
        guard let validData = data,
            let image = UIImage(data: validData, scale: 0) else {
                return .failure(AFError.responseSerializationFailed(reason: .inputDataNil))
        }
        
        return .success(image)
    }
}


extension DataRequest {
    /// Creates a response serializer that returns the associated data as-is.
    ///
    /// - returns: A data response serializer.
    public static func imageResponseSerializer() -> DataResponseSerializer<UIImage> {
        return DataResponseSerializer { _, response, data, error in
            return Request.serializeResponseImage(response: response, data: data, error: error)
        }
    }
    
    @discardableResult
    public func responseImage(
        queue: DispatchQueue? = nil,
        completionHandler: @escaping (DataResponse<UIImage>) -> Void)
        -> Self
    {
        return response(
            queue: queue,
            responseSerializer: DataRequest.imageResponseSerializer(),
            completionHandler: completionHandler
        )
    }
}
