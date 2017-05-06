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
    fileprivate var maxDownloadCount: Int = 1
    fileprivate var minURLCount: Int = 15
    fileprivate var minImageCount: Int = 20
    
    fileprivate let service: FeedService
    fileprivate var timer: Timer?
    fileprivate var timerCount: Int = 0
    
    fileprivate var currentDounloads: [URL: DataRequest] = [:]
    fileprivate var feedItems: [ItemModel] = []
    fileprivate var loadedImages: ImageDictionary = ImageDictionary()
    
    fileprivate weak var currentImage: UIImage? = nil
    
    var delay: Int = 5
    weak var delegate: SlideShowTaskDelegate?
    
    deinit {
        print("deinit: SlideShowTask")
    }
    
    init(contentType: FeedService.ContentType = .photos) {
        self.service = FeedService(contentType: contentType)
        super.init()
        self.timer = Timer.scheduledTimer(timeInterval: interval,
                                          target: self,
                                          selector: #selector(self.onUpdateTimer),
                                          userInfo: nil,
                                          repeats: true)
    }

    public func start() {
        guard let timer = self.timer else { return }
        print("start")
        timer.fire()
        onUpdateTimer(timer)
    }
    
    public  func stop() {
        print("stop")
        currentImage = nil
        currentDounloads.forEach { $1.cancel() }
        currentDounloads.removeAll()
        timer?.invalidate()
    }
    
}

fileprivate extension SlideShowTask {
    
    @objc func onUpdateTimer(_ timer: Timer) {
        defer {
            self.timerCount = (self.timerCount + 1)%self.delay
        }
        let isShowNextImage = self.timerCount == 0
        if isShowNextImage {
            slideShowNextImage()
        }
        
        self.loadFeeed()
        self.loadNextImage()
        
        self.delegate?.slideShow?(timerCount: self.timerCount)
    }
    
    func loadFeeed() {
        if self.minURLCount < self.feedItems.count { return }
        self.service.load { [weak self] in
            self?.feedItems += $0
        }
    }
    
    func loadNextImage() {
        let cacheableCount = minImageCount - loadedImages.count
        let downloadableCount =  maxDownloadCount - currentDounloads.count
        let count = max(0, min(cacheableCount, downloadableCount))
        
        if count == 0 { return }
        guard let media = self.feedItems.shift() else { return }
        loadImage(by: media, completed: { [weak self] image, sizeType in
            self?.loadedImages.append(sizeType, image: image)
            //다음 사진 로드 시도!
            self?.loadNextImage()
            
            
            if self?.currentImage == nil {
                self?.timerCount = 0
                self?.slideShowNextImage()
            }
            
        })
    }
    
    
    func slideShowNextImage() {
        guard let image = self.loadedImages.shift() else { return }
        self.delegate?.slideShow(by: image)
        self.currentImage = image
    }
    
    
    ///========
    func loadImage(by item: ItemModel, completed: @escaping (UIImage, ItemModel.SizeType)->Void) {
        //로드된게 많으면 해상도를 올려주자!
        //평균적으로 이미지 한장을 호출하는데 사용한 시간
        let count = loadedImages.count
        var sizeType: ItemModel.SizeType = .base
        
        if count < max(2, minImageCount/5) {
            sizeType = .thumbnail
        } else if count < max(2, minImageCount/4) {
            sizeType = .small
        } else if count < max(2, minImageCount/3) {
            sizeType = .medium
        }
        
        guard let url = item.mediaURL(by: sizeType) else { return }
        
        let request = Alamofire.request(url)
        currentDounloads[url] = request
        
        request
            .responseImage(queue: DispatchQueue.global()) { [weak self] (response: DataResponse<UIImage>) in
                self?.currentDounloads.removeValue(forKey: url)
                switch response.result {
                case .success(let image):
                    DispatchQueue.main.async {
                        completed(image, sizeType)
                    }
                case .failure(_): break
                }
        }
    }
}


extension SlideShowTask {
    class ImageDictionary {
        typealias SizeType = ItemModel.SizeType
        private let types: [SizeType] = [.base, .medium, .small, .thumbnail]
        private var images: [SizeType : [UIImage]] = [:]
        
        
        var count: Int {
            return images.map { $1 }.flatMap { $0 }.count
        }
        
        subscript(key: SizeType) -> [UIImage] {
            get {
                if self.images[key] == nil { self.images[key] = [] }
                return self.images[key] ?? []
            }
            set {
                self.images[key] = newValue
            }
        }
        
        func append(_ key: SizeType, image: UIImage) {
            if self.images[key] == nil { self.images[key] = [] }
            self.images[key]?.append(image)
        }
        
        func shift() -> UIImage? {
            for type in types {
                guard let image = self.images[type]?.shift() else { continue }
                return image
            }
            return nil
        }
        
    }
}
