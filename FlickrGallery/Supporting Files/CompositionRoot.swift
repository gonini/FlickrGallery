//
//  CompositionRoot.swift
//  FlickrGallery
//
//  Created by 장공의 on 27/03/2019.
//  Copyright © 2019 gonini. All rights reserved.
//

import Foundation

import GalleryDomain
import SwinjectStoryboard

extension SwinjectStoryboard {
    @objc class func setup() {
        defaultContainer.storyboardInitCompleted(TicketOfficeVC.self) { _, c in
            c.reactor = GalleryTicketReactor()
        }
    }
}
