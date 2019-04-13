//
//  UIImageView+Load.swift
//  FlickrGallery
//
//  Created by 장공의 on 02/04/2019.
//  Copyright © 2019 gonini. All rights reserved.
//

import UIKit

extension UIImageView {
    func load(data: Data, duration: TimeInterval) {
        DispatchQueue.global().async {
            guard let image = UIImage(data: data) else {
                return
            }
            DispatchQueue.main.async { [weak self] in
                guard let `self` = self else { return }
                self.fadeOut(duration) { _ in
                    self.image = image
                    self.fadeIn(duration)
                }
            }
        }
    }
}

extension UIImageView {
    // https://stackoverflow.com/questions/28288476/fade-in-and-fade-out-in-animation-swift
    func fadeIn(_ duration: TimeInterval = 0.5,
                delay: TimeInterval = 0.0,
                completion: @escaping ((Bool) -> Void) = { (finished: Bool) -> Void in }) {
        UIView.animate(withDuration: duration, delay: delay, options: UIView.AnimationOptions.curveEaseIn, animations: {
            self.alpha = 1.0
        }, completion: completion)  }
    
    func fadeOut(_ duration: TimeInterval = 0.5,
                 delay: TimeInterval = 0.0,
                 completion: @escaping (Bool) -> Void = { (finished: Bool) -> Void in }) {
        UIView.animate(withDuration: duration, delay: delay, options: UIView.AnimationOptions.curveEaseIn, animations: {
            self.alpha = 0.0
        }, completion: completion)
    }
}
