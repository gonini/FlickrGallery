//
//  CompositionRoot.swift
//  FlickrGallery
//
//  Created by 장공의 on 27/03/2019.
//  Copyright © 2019 gonini. All rights reserved.
//

import UIKit

import GalleryDomain
import FlickerService
import RxSwift
import Swinject
import SwinjectStoryboard

extension SwinjectStoryboard {
    @objc class func setup() {
        defaultContainer.register(NetworkStatusService.self) { _ in
            return ReachabilityService()
        }
        
        defaultContainer.register(FileDownloadService.self) { _ in
            return ImageDownloadService()
        }
        
        defaultContainer.register(GalleryFeedService.self) { _ in
            return FlickerFeedService()
        }
        
        defaultContainer.register(GlobalStreamService.self) { _ in
            return TemporaryGlobalStream()
        }.inObjectScope(.container)
     
        defaultContainer.register(LogService.self) { _ in
            return BasicLogger()
        }
        
        defaultContainer.register(TicketOfficeReactor.self) { container in
            return .init(globalStream: container.resolve(GlobalStreamService.self)!,
                         networkStatus: container.resolve(NetworkStatusService.self)!,
                         logger: container.resolve(LogService.self)!)
        }
        
        defaultContainer.register(GalleryReactor.self) { container in
            return .init(globalStream: container.resolve(GlobalStreamService.self)!,
                         downloadService: container.resolve(FileDownloadService.self)!,
                         feedService: container.resolve(GalleryFeedService.self)!,
                         logger: container.resolve(LogService.self)!)
        }
     
        defaultContainer.register(GalleryVC.self) { container in
            let storyboard = UIStoryboard(name: "Gallery", bundle: nil)
            guard let ret = storyboard.instantiateViewController(withIdentifier: "GalleryVC") as? GalleryVC else {
                fatalError("casting failed")
            }
            
            ret.reactor = container.resolve(GalleryReactor.self)
            return ret
        }.inObjectScope(.transient)
 
        defaultContainer.storyboardInitCompleted(TicketOfficeVC.self) { container, resolver in
            resolver.reactor = container.resolve(TicketOfficeReactor.self)
            resolver.galleryVC = container.resolve(GalleryVC.self)
        }
    }
}
