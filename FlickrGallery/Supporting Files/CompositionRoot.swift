//
//  CompositionRoot.swift
//  FlickrGallery
//
//  Created by 장공의 on 27/03/2019.
//  Copyright © 2019 gonini. All rights reserved.
//

import UIKit

import GalleryDomain
import RxSwift
import Swinject
import SwinjectStoryboard

struct GalleryVCLazyHolder {
    let galleryVC: Lazy<GalleryVC>
}

extension SwinjectStoryboard {
    @objc class func setup() {
        defaultContainer.register(ReplaySubject<ViewingTime>.self) { _ in
            return .create(bufferSize: 1)
        }.inObjectScope(.container)
        
        defaultContainer.register(TicketOfficeReactor.self) { c in
            return .init(viewingTimeStream: c.resolve(ReplaySubject<ViewingTime>.self)!)
        }
     
        defaultContainer.register(GalleryReactor.self) { c in
            return .init(viewingTimeStream: c.resolve(ReplaySubject<ViewingTime>.self)!)
        }
     
        defaultContainer.register(GalleryVC.self) { c in
            let storyboard = UIStoryboard(name: "Gallery", bundle: nil)
            let ret = storyboard.instantiateViewController(withIdentifier: "GalleryVC") as! GalleryVC
            ret.reactor = c.resolve(GalleryReactor.self)
            return ret
        }
        
        defaultContainer.register(GalleryVCLazyHolder.self) {
            return .init(galleryVC: $0.resolve(Lazy<GalleryVC>.self)!)
        }
        
        defaultContainer.storyboardInitCompleted(TicketOfficeVC.self) { c, r in
            r.reactor = c.resolve(TicketOfficeReactor.self)
            r.lazyGalleryVC = c.resolve(GalleryVCLazyHolder.self)
        }
    }
}
