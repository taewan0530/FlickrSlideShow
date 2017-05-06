//
//  SlideShowViewController.swift
//  FlickrSlideShow
//
//  Created by taewan on 2017. 5. 6..
//  Copyright © 2017년 taewan. All rights reserved.
//

import UIKit

final class SlideShowViewController: BaseViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var delaySlider: UISlider!
    
    private var slideShowTask: SlideShowTask?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setup()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.slideShowTask?.start()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.slideShowTask?.stop()
    }

    private func setup() {
        self.slideShowTask = SlideShowTask(contentType: .photos)
        self.slideShowTask?.delegate = self
        delaySliderDidChange(self.delaySlider)
    }
    
    @IBAction func delaySliderDidChange(_ slider: UISlider) {
        let delay = Int(slider.value)
        self.title = "delay: \(delay)"
        self.slideShowTask?.delay = Double(slider.value)
    }
}


extension SlideShowViewController: SlideShowTaskDelegate {
    func imageSlide(_ nextImage: UIImage) {
        UIView.transition(
            with: self.imageView,
            duration: 0.4,
            options: [.transitionCrossDissolve],
            animations: {
                [weak self] in
                self?.imageView.image = nextImage
            }, completion: nil)
    }
}
