//
//  SlideShowViewModel.swift
//  FlickrSlideShow
//
//  Created by taewan on 2017. 5. 3..
//  Copyright © 2017년 taewan. All rights reserved.
//

import UIKit
import Alamofire

protocol SlideShowTaskDelegate: class {
    func imageSlide(_ nextImage: UIImage)
}


final class SlideShowTask: NSObject {
    //최소 인터벌 타임.
    private let interval: Double = 1.0//sec
    
    //동시 다운로드 최대 갯수.
    private let maxDownloadCount: Int = 1
    
    //n개의 url이 없으면 더 불러온다.
    private let minURLCount: Int = 15
    
    //n개 이미지 이하일때 이미지를 로드한다.
    private let minImageCount: Int = 20
    
    
    private let service: FeedService
    private var timer: Timer?
    private var timerCount: Int = 0
    
    private var downloadRequests: [URL: DataRequest] = [:]
    
    private var items: [ItemModel] = []
    
    private var loadedImages: [ItemModel.SizeType : [UIImage]] = [:]
    
    private var loadedImagesCount: Int {
       return loadedImages.map { $1 }.flatMap { $0 }.count
    }
    
    private var currentImage: UIImage? = nil
    //고화질 이미지부터 내보내주자.
    private var nextImage: UIImage? {
        for type in ItemModel.SizeType.types {
            guard let image = loadedImages[type]?.shift() else { continue }
            return image
        }
        return nil
    }
    
    var delay: Double = 1.0
    weak var delegate: SlideShowTaskDelegate?
    
    deinit {
        print("deinit: SlideShowTask")
    }
    
    init(contentType: FeedService.ContentType = .photos) {
        self.service = FeedService(contentType: contentType)
        super.init()
        self.timer = Timer.scheduledTimer(timeInterval: interval,
                                          target: self,
                                          selector: #selector(self.updateDidTimer),
                                          userInfo: nil,
                                          repeats: true)
        self.load()
    }
    
    func updateDidTimer(_ timer: Timer) {
        self.timerCount = (timerCount + 1)%Int(delay)
        print("counter:\(timerCount), delay:\(delay)")
        self.load()
        self.updateImages()
        if self.timerCount == 0 {
            print("next")
            updateImage()
        }
    }
    
    func updateImage() {
        guard let image = self.nextImage else { return }
        self.delegate?.imageSlide(image)
        self.currentImage = image
    }
    
    func start() {
        print("start")
        timer?.fire()
    }
    
    func stop() {
        print("stop")
        currentImage = nil
        downloadRequests.forEach { $1.cancel() }
        downloadRequests = [:]
        timer?.invalidate()
    }
    
    private func load() {
        if minURLCount < items.count { return }
        service.load { [weak self] in
            self?.items += $0
            self?.updateImages()
        }
    }
    
    
    private func loadImage(by item: ItemModel, completed: @escaping (UIImage, ItemModel.SizeType)->Void) {
        //로드된게 많으면 해상도를 올려주자!
        //평균적으로 이미지 한장을 호출하는데 사용한 시간
        let sizeType = item.mediaSizeType(leftCount: loadedImagesCount, maxCount: minImageCount)
        guard let url = item.mediaURL(by: sizeType) else { return }
        
        let request = Alamofire.request(url)
        downloadRequests[url] = request
        
        request
            .responseImage(queue: DispatchQueue.global()) { [weak self] (response: DataResponse<UIImage>) in
            self?.downloadRequests.removeValue(forKey: url)
            switch response.result {
            case .failure(_): break
            case .success(let image):
                DispatchQueue.main.async {
                    completed(image, sizeType)
                }
            }
        }
    }
    
    
    private func updateImages() {
        let cacheableCount = minImageCount - loadedImagesCount
        let downloadableCount =  maxDownloadCount - downloadRequests.count
        let count = max(0, min(cacheableCount, downloadableCount))
        
        if count == 0 { return }
        
        print("urls:\(items.count), loaded:\(loadedImagesCount), downloading:\(downloadRequests.count)")
        
        if let media = items.shift() {
            loadImage(by: media, completed: { [weak self] image, sizeType in
                print(image.size)
                if self?.loadedImages[sizeType] == nil {
                    self?.loadedImages[sizeType] = []
                }
                
                self?.loadedImages[sizeType]?.append(image)
                self?.updateImages()
                
                if self?.currentImage == nil {
                    self?.updateImage()
                }
            })
        }
    }
}
