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

public typealias HTTPHeaders = [String: String]

public struct FlickerFeedService: GalleryFeedService {
    private static let flickerFeedUrl = URL(string: "https://api.flickr.com/services/feeds/photos_public.gne")!
    private static let parm: Parameters = [
        "tags": "landscape,portrait",
        "tagmode": "any",
        "format": "json",
        "jsoncallback": "?"
    ]
    
    private let lastPublishedDateStream = BehaviorSubject<Date>(value: .init(timeIntervalSince1970: 0))
    private let lastModifiedSubject = BehaviorSubject<String>(value: "")
    
    public init() { }
    
    public func observeFeeds(refreshInterval: TimeInterval) -> Observable<FeedItem> {
        return updateGalleryFeedsRepeatedly(refreshInterval)
            .withLatestFrom(lastPublishedDateStream) { (feeds, lastPublishedDate) -> [FeedItem] in
                feeds.filter { $0.publishedDate > lastPublishedDate }
                    .sorted { $0.publishedDate > $1.publishedDate }
            }
            .filter { !$0.isEmpty }
            .do(onNext: { self.lastPublishedDateStream.onNext($0.first!.publishedDate) })
            .flatMap({ Observable.from($0) })
    }

    private func updateGalleryFeedsRepeatedly(_ refreshInterval: RxTimeInterval) -> Observable<[FeedItem]> {
        let timer = Observable<Int>
            .interval(refreshInterval,
                      scheduler: ConcurrentDispatchQueueScheduler(qos: .background))
            .startWith(0)
        return timer.withLatestFrom(lastModifiedSubject)
            .concatMap(observeGalleryFeeds)
    }
    
    private func observeGalleryFeeds(_ lastModifiedDate: String) -> Observable<[FeedItem]> {
        let headers: HTTPHeaders = [
            HTTPHeader.ifModifiedSince: lastModifiedDate
        ]
        
        return RxAlamofire
            .request(.get, FlickerFeedService.flickerFeedUrl,
                     parameters: FlickerFeedService.parm,
                     encoding: URLEncoding(destination: .queryString), headers: headers)
            .responseString()
            .catchError(Observable.error)
            .filter { (response, _) -> Bool in response.statusCode == 200 }
            .map { (response: HTTPURLResponse, data) -> String in
                if let IMS = response.allHeaderFields[HTTPHeader.lastModified] as! String? {
                    self.lastModifiedSubject.onNext(IMS)
                }
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

struct HTTPHeader {
    static let ifModifiedSince = "If-Modified-Since"
    static let lastModified = "Last-Modified"
}
