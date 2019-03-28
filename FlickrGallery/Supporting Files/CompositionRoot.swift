//
//  CompositionRoot.swift
//  FlickrGallery
//
//  Created by 장공의 on 27/03/2019.
//  Copyright © 2019 gonini. All rights reserved.
//

import UIKit

import GalleryDomain
import Swinject
import SwinjectStoryboard

struct LazyGalleryVC {
    let galleryVC: Lazy<GalleryVC>
}

extension SwinjectStoryboard {
    @objc class func setup() {
        defaultContainer.register(GalleryVC.self) { _ in
            let storyboard = UIStoryboard(name: "Gallery", bundle: nil)
            return storyboard.instantiateViewController(withIdentifier: "GalleryVC") as! GalleryVC
        }
        
        defaultContainer.register(LazyGalleryVC.self) {
            return LazyGalleryVC(galleryVC: $0.resolve(Lazy<GalleryVC>.self)!)
        }
        
        defaultContainer.storyboardInitCompleted(TicketOfficeVC.self) { c, r in
            r.reactor = GalleryTicketReactor()
            r.lazyGalleryVC = c.resolve(LazyGalleryVC.self)
        }
    }
}
