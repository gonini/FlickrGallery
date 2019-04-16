//
//  NewsFeedModel.swift
//  GalleryDomain
//
//  Created by 장공의 on 30/03/2019.
//  Copyright © 2019 gonini. All rights reserved.
//

import Foundation

import RxSwift
import Alamofire
import RxAlamofire
import ObjectMapper

public protocol GalleryFeedService {
    func observeFeeds(refreshInterval: TimeInterval) -> Observable<FeedItem>
}

public class FeedItem: Mappable {
    public var title: String!
    public var publishedText: String!
    public var publishedDate: Date!
    public var media: Media!
    public var imageUrl: String!
    
    required public init?(map: Map) { }
    
    public func mapping(map: Map) {
        title <- map["title"]
        publishedText <- (map["published"])
        media <- map["media"]
        imageUrl = media.url
        publishedDate = publishedText.toFlickerFormatDate()
    }
    
}

public class Media: Mappable {
    public var url: String!
    
    required public init?(map: Map) { }
    
    public func mapping(map: Map) {
        url <- map["m"]
    }
}
