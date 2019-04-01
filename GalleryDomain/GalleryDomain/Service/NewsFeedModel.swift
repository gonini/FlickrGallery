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
    private let lastPublishedDateStream = BehaviorSubject<Date>(value: .init(timeIntervalSince1970: 0))
    
    lazy var galleryFeeds = self.filterNewGalleryFeeds()
    
    private func filterNewGalleryFeeds() -> Observable<FeedItem> {
        return updateGalleryFeedsRepeatedly(publishInterval: 5.0)
            .withLatestFrom(lastPublishedDateStream) { (feeds, lastPublishedDate) -> [FeedItem] in
                feeds.filter { $0.publishedDate > lastPublishedDate }
                    .sorted { $0.publishedDate > $1.publishedDate }
            }
            .filter { !$0.isEmpty }
            .do(onNext: { self.lastPublishedDateStream.onNext($0.first!.publishedDate) })
            .flatMap({ Observable.from($0) })
        
    }
    
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
        media <-  map["media"]
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
