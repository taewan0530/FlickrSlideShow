//
//  SlideShowQueue.swift
//  FlickrSlideShow
//
//  Created by taewan on 2017. 5. 7..
//  Copyright © 2017년 taewan. All rights reserved.
//

import Foundation
import UIKit
import Alamofire

final class SlideShowQueue {
    
    fileprivate let loadedImages = ImageDictionary()
    
    private var waitingOperation: [SlideShowQueue.Operation] = []
    private let queue = OperationQueue()
    
    var nextImage: UIImage? {
        updateOperation()
        return loadedImages.shift()
    }
    
    var operationCount: Int {
        return queue.operationCount + waitingOperation.count
    }
    
    var maxLoadedImageCount: Int = 20
    var maxConcurrentOperationCount: Int {
        get { return queue.maxConcurrentOperationCount }
        set { queue.maxConcurrentOperationCount = newValue }
    }
    
    init() {
        self.maxConcurrentOperationCount = 3
    }
    
    func pause() {
        queue.isSuspended = true
    }
    
    func resume() {
        queue.isSuspended = false
    }
    
    func cancelAll() {
        queue.cancelAllOperations()
        waitingOperation.removeAll()
        loadedImages.removeAll()
    }
    
    func addOperations(_ items: [ItemModel]) {
        items.forEach {
            self.addOperation($0)
        }
    }
    
    func addOperation(_ item: ItemModel) {
        let op = SlideShowQueue.Operation(queue: self, item: item)
        waitingOperation.append(op)
        updateOperation()
    }
    
    private func updateOperation() {
        let loadableCount = max(0, maxLoadedImageCount - (queue.operationCount + loadedImages.count))
        print("operationCount:\(queue.operationCount), loadedImage:\(loadedImages.count), waitingOperation:\(waitingOperation.count)")
        if loadableCount == 0 { return }
        (0...loadableCount).forEach { _ in
            guard let operation = waitingOperation.shift() else {
                return
            }
            queue.addOperation(operation)
        }
    }
}


fileprivate extension SlideShowQueue {
    class ImageDictionary {
        typealias SizeType = ItemModel.SizeType
        private let types: [SizeType] = [.base, .medium, .small, .thumbnail]
        private var images: [SizeType : [UIImage]] = [:]
        
        var count: Int {
            return images.map { $1 }.flatMap { $0 }.count
        }
        
        func removeAll() {
            images.removeAll()
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
    
    
    
    class Operation: Foundation.Operation {
        enum State {
            case ready, executing, finished
            var keyPath: String {
                switch self {
                case .ready: return "isReady"
                case .executing: return "isExecuting"
                case .finished: return "isFinished"
                }
            }
        }
        
        
        private var state: State = .ready {
            willSet {
                willChangeValue(forKey: newValue.keyPath)
                willChangeValue(forKey: state.keyPath)
            }
            didSet {
                didChangeValue(forKey: oldValue.keyPath)
                didChangeValue(forKey: state.keyPath)
            }
        }
        
        override var isReady: Bool {
            return super.isReady && state == .ready
        }
        
        override var isExecuting: Bool {
            return state == .executing
        }
        
        
        override var isFinished: Bool {
            return state == .finished
        }
        
        override var isAsynchronous: Bool {
            return true
        }
        
        
        override func start() {
            if self.isCancelled {
                state = .finished
            } else {
                state = .executing
                main()
            }
        }
        
        override func cancel() {
            super.cancel()
            request?.cancel()
        }
        
        private let item: ItemModel
        private var request: DataRequest?
        private weak var queue: SlideShowQueue?
        init(queue: SlideShowQueue, item: ItemModel) {
            self.queue = queue
            self.item = item
        }
        
        override func main() {
            super.main()
            if self.isCancelled {
                state = .finished
            } else {
                state = .executing
            }
            
            let loadedCount = self.queue?.loadedImages.count ?? 0
            let sizeType: ItemModel.SizeType
            
            if loadedCount < 5 {
                sizeType = .thumbnail
            } else if loadedCount < 7 {
                sizeType = .small
            } else if loadedCount < 9 {
                sizeType = .medium
            } else {
                sizeType = .base
            }
            
            guard let url = item.mediaURL(by: sizeType) else { return }
            request = Alamofire.request(url)
            request?.responseImage(queue: DispatchQueue.global()) { [weak self] (response: DataResponse<UIImage>) in
                switch response.result {
                case .success(let image):
                    self?.queue?.loadedImages.append(sizeType, image: image)
                case .failure(_):
                    break
                }
                self?.state = .finished
            }
        }
        
    }
}

