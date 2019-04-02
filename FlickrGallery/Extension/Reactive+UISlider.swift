//
//  Reactive+UISlider.swift
//  FlickrGallery
//
//  Created by 장공의 on 02/04/2019.
//  Copyright © 2019 gonini. All rights reserved.
//
import GalleryDomain
import Foundation
import RxSwift
import RxCocoa

extension Reactive where Base: UISlider {
    var timeValue: ControlEvent<ViewingTime> {
        let source = base.rx.value.map { ViewingTime(exactly: round($0))! }
        return ControlEvent(events: source)
    }
}
