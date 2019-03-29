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

struct GalleryVCLazyHolder {
    let galleryVC: Lazy<GalleryVC>
}

extension SwinjectStoryboard {
    @objc class func setup() {
        defaultContainer.register(GalleryVC.self) { _ in
            let storyboard = UIStoryboard(name: "Gallery", bundle: nil)
            let ret = storyboard.instantiateViewController(withIdentifier: "GalleryVC") as! GalleryVC
            ret.reactor = GalleryReactor()
            return ret
        }
        
        defaultContainer.register(GalleryVCLazyHolder.self) {
            return GalleryVCLazyHolder(galleryVC: $0.resolve(Lazy<GalleryVC>.self)!)
        }
        
        defaultContainer.storyboardInitCompleted(TicketOfficeVC.self) { c, r in
            r.reactor = TicketOfficeReactor()
            r.lazyGalleryVC = c.resolve(GalleryVCLazyHolder.self)
        }
    }
}
