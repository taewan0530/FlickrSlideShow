//
//  BaseViewController.swift
//  FlickrSlideShow
//
//  Created by taewan on 2017. 5. 6..
//  Copyright © 2017년 taewan. All rights reserved.
//

import UIKit

class BaseViewController: UIViewController {

    deinit {
        print("deinit - \(type(of: self).description().components(separatedBy: ".").last ?? "-")")
    }

}
