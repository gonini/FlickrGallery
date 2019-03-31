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

struct GalleryFeedModel {
    private static let flickerFeedUrl = URL(string: "https://api.flickr.com/services/feeds/photos_public.gne")!
    
    lazy var galleryFeeds: Observable<[FeedItem]> = self.updateGalleryFeedsRepeatedly(publishInterval: 5.0)
    
    private func updateGalleryFeedsRepeatedly(publishInterval: RxTimeInterval) -> Observable<[FeedItem]> {
        let timer = Observable<Int>
            .interval(publishInterval,
                      scheduler: ConcurrentDispatchQueueScheduler(qos: .background))
            .startWith(0)
        
        return timer.concatMap { _ in self.observeGalleryFeeds() }
    }
    
    private func observeGalleryFeeds() -> Observable<[FeedItem]> {
        let parm: Parameters = [
            "tags": "landscape,portrait",
            "tagmode": "any",
            "format": "json",
            "jsoncallback": "?"
        ]
        
        return RxAlamofire
            .request(.get, GalleryFeedModel.flickerFeedUrl,
                           parameters: parm,
                           encoding: URLEncoding(destination: .queryString))
            .responseString()
            .catchError(Observable.error)
            .filter { (res, _) -> Bool in res.statusCode == 200 }
            .map { (_, data) -> String in
                var ret = data
                ret.removeFirst()
                ret.removeLast()
                return ret
            }
            .map { $0.data(using: .utf8)! }
            .map { try JSONSerialization.jsonObject(with: $0) as! [String: Any] }
            .map { json -> [FeedItem] in
                if let feeds = Mapper<FeedItem>().mapArray(JSONObject: json["items"]) {
                    return feeds
                } else {
                    return []
                }
        }
    }
}

class FeedItem: Mappable {
    var title: String!
    var published: Date!
    var media: Media!
    var imageUrl: String!
    
    required init?(map: Map) { }
    
    func mapping(map: Map) {
        title <- map["title"]
        published <- (map["published"], DateTransform())
        media <-  map["media"]
        imageUrl = media.url
    }
}

class Media: Mappable {
    var url: String!
    
    required init?(map: Map) { }
    
    func mapping(map: Map) {
        url <- map["m"]
    }
}
