//
//  SlideShowViewModel.swift
//  FlickrSlideShow
//
//  Created by taewan on 2017. 5. 3..
//  Copyright © 2017년 taewan. All rights reserved.
//

import UIKit
import Alamofire

@objc
protocol SlideShowTaskDelegate: class {
    func slideShow(by nextImage: UIImage)
    @objc optional func slideShow(timerCount: Int)
}


final class SlideShowTask: NSObject {
    fileprivate var interval: Double = 1.0
    fileprivate var minItemCount: Int = 15
    
    fileprivate let queue: SlideShowQueue
    fileprivate let service: FeedService
    fileprivate var timer: Timer?
    fileprivate var timerCount: Int = 0
    
    fileprivate weak var currentImage: UIImage? = nil
    
    var delay: Int = 5
    weak var delegate: SlideShowTaskDelegate?
    
    deinit {
        print("deinit: SlideShowTask")
    }
    
    init(contentType: FeedService.ContentType = .photos) {
        self.queue = SlideShowQueue()
        self.service = FeedService(contentType: contentType)
        super.init()
        self.timer = Timer.scheduledTimer(timeInterval: interval,
                                          target: self,
                                          selector: #selector(self.onUpdateTimer),
                                          userInfo: nil,
                                          repeats: true)
    }
    
    public func start() {
        print("start")
        self.timer?.fire()
        self.queue.resume()
        if let timer = self.timer {
            self.onUpdateTimer(timer)
        }
    }
    
    public  func stop() {
        print("stop")
        self.queue.pause()
        self.queue.cancelAll()
        self.currentImage = nil
        self.timer?.invalidate()
    }
    
}

fileprivate extension SlideShowTask {
    
    @objc func onUpdateTimer(_ timer: Timer) {
        defer {
            self.timerCount = (self.timerCount + 1)%self.delay
        }
        
        let isShowNextImage = self.timerCount == 0 || currentImage == nil
        
        if isShowNextImage {
            self.timerCount = 0//카운트를 다시 0으로 바꾸자.
            self.slideShowNextImage()
        }
        
        self.loadFeeed()
        self.delegate?.slideShow?(timerCount: self.timerCount)
    }
    
    func loadFeeed() {
        guard queue.operationCount < minItemCount else { return }
        
        self.service.load { [weak self] in
            self?.queue.addOperations($0)
        }
    }
    
    func slideShowNextImage() {
        guard let image = queue.nextImage else { return }
        self.delegate?.slideShow(by: image)
        self.currentImage = image
    }
    
}
