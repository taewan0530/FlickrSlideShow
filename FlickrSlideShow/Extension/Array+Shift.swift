//
//  Array+Shift.swift
//  FlickrSlideShow
//
//  Created by taewan on 2017. 5. 3..
//  Copyright © 2017년 taewan. All rights reserved.
//

import Foundation


extension Array {
    
    /// 맨 앞에 배열꺼내기
    ///
    /// - Returns: first element
    mutating func shift() -> Element? {
        return 0 < self.count ? self.remove(at: 0) : nil
    }
}

