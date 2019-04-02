//
//  ViewingTimeSlider.swift
//  FlickrGallery
//
//  Created by 장공의 on 02/04/2019.
//  Copyright © 2019 gonini. All rights reserved.
//

import Foundation
import UIKit

import GalleryDomain
import RxSwift

@objc protocol ViewingTimeSlider {
    var viewingTimeSlider: UISlider! { get set }
}

extension ViewingTimeSlider {
    func bindRange(rangeStream: Observable<ViewingTimeRange>) -> Disposable {
        return rangeStream.distinctUntilChanged()
            .map { (Float($0.minTime), Float($0.maxTime)) }
            .observeOn(MainScheduler.instance)
            .bind(onNext: { [weak self] in
                guard let `self` = self else { return }
                self.viewingTimeSlider.minimumValue = $0.0
                self.viewingTimeSlider.maximumValue = $0.1
            })
    }
}
