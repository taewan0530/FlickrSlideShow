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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setup()
    }

    private func setup() {
        delaySliderDidChange(self.delaySlider)
    }
    
    @IBAction func delaySliderDidChange(_ slider: UISlider) {
        let delay = Int(slider.value)
        self.title = "delay: \(delay)"
    }
}


extension SlideShowViewController {
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
