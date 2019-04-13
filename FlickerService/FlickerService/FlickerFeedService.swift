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

public class FlickerFeedService: GalleryFeedService {
    private static let flickerFeedUrl = URL(string: "https://api.flickr.com/services/feeds/photos_public.gne")!
    private static let parm: Parameters = [
        "tags": "landscape,portrait",
        "tagmode": "any",
        "format": "json",
        "jsoncallback": "?"
    ]
    
    private var lastPublishedDateStream: BehaviorSubject<Date>!
    private var lastModifiedSubject: BehaviorSubject<String>!
    
    public init() { }
    
    public func observeFeeds(refreshInterval: TimeInterval) -> Observable<FeedItem> {
        self.lastPublishedDateStream = .init(value: .init(timeIntervalSince1970: 0))
        self.lastModifiedSubject = .init(value: "")
        return observeOnlyNewFeeds(refreshInterval)
    }
    
    private func observeOnlyNewFeeds(_ refreshInterval: RxTimeInterval) -> Observable<FeedItem> {
        return pollFeedsRepeatedly(refreshInterval)
            .withLatestFrom(lastPublishedDateStream) { (feeds, lastPublishedDate) -> [FeedItem] in
                feeds.filter { $0.publishedDate > lastPublishedDate }
                    .sorted { $0.publishedDate > $1.publishedDate }
            }
            .filter { !$0.isEmpty }
            .do(onNext: { self.lastPublishedDateStream.onNext($0.first!.publishedDate) })
            .flatMap({ Observable.from($0) })
    }
    
    private func pollFeedsRepeatedly(_ refreshInterval: RxTimeInterval) -> Observable<[FeedItem]> {
        let timer = Observable<Int>
            .interval(refreshInterval,
                      scheduler: ConcurrentDispatchQueueScheduler(qos: .background))
            .startWith(0)
        return timer.withLatestFrom(lastModifiedSubject)
            .concatMap(requestFeeds)
    }
    
    private func requestFeeds(_ lastModifiedDate: String) -> Observable<[FeedItem]> {
        let headers: HTTPHeaders = [
            HTTPHeader.ifModifiedSince: lastModifiedDate
        ]
        
        return RxAlamofire
            .request(.get, FlickerFeedService.flickerFeedUrl,
                     parameters: FlickerFeedService.parm,
                     encoding: URLEncoding(destination: .queryString), headers: headers)
            .responseString()
            .filter { (response, _) -> Bool in response.statusCode == 200 }
            .catchError(Observable.error)
            .map { (response, result) -> String in
                self.updateIMS(response)
                return result
            }
            .map { $0.removeBothEnds() }
            .map { result -> [String: Any] in
                guard let data = result.data(using: .utf8) else { return .init() }
                guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    return .init()
                }
                return json
            }
            .map { json -> [FeedItem] in
                guard let feeds = Mapper<FeedItem>().mapArray(JSONObject: json["items"]) else {
                    return .init()
                }
                return feeds
            }
    }
    
    private func updateIMS(_ response: HTTPURLResponse) {
        if let IMS = response.allHeaderFields[HTTPHeader.lastModified] as? String {
            self.lastModifiedSubject.onNext(IMS)
        }
    }
}

struct HTTPHeader {
    static let ifModifiedSince = "If-Modified-Since"
    static let lastModified = "Last-Modified"
}

extension String {
    func removeBothEnds() -> String {
        guard self.count > 2 else { return self }
        var ret = self
        ret.removeFirst()
        ret.removeLast()
        return ret
    }
}
