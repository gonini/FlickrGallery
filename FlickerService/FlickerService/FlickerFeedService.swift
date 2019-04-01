//
//  FlickerFeedService.swift
//  FlickerService
//
//  Created by 장공의 on 01/04/2019.
//  Copyright © 2019 gonini. All rights reserved.
//

import Foundation

import GalleryDomain
import RxSwift
import Alamofire
import RxAlamofire
import ObjectMapper

public struct FlickerFeedService: GalleryFeedService {
    private static let flickerFeedUrl = URL(string: "https://api.flickr.com/services/feeds/photos_public.gne")!
    private let lastPublishedDateStream = BehaviorSubject<Date>(value: .init(timeIntervalSince1970: 0))
    
    public init() { }
    
    public func observeFeeds(refreshInterval: TimeInterval) -> Observable<FeedItem> {
        return updateGalleryFeedsRepeatedly(publishInterval: refreshInterval)
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
            .request(.get, FlickerFeedService.flickerFeedUrl,
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
