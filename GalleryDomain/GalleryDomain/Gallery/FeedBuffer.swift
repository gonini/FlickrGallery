//
//  FeedBuffer.swift
//  GalleryDomain
//
//  Created by 장공의 on 13/04/2019.
//  Copyright © 2019 gonini. All rights reserved.
//

import Foundation

class FeedBuffer<T: FeedSelectionStrategy> {
    private let feeds: SynchronizedArray<T.Feed> = .init()
    var feedSelection: T?
    
    var currentFeed: T.Feed? {
        return feedSelection?.selectFeed(feeds)
    }
    
    func append(_ element: T.Feed) {
        feeds.append(element)
    }
    
    func removeAll() {
        feeds.removeAll()
    }
}

protocol FeedType { }

extension URL: FeedType { }

protocol FeedSelectionStrategy {
    associatedtype Feed: FeedType
    func selectFeed(_ feeds: SynchronizedArray<Feed>) -> Feed?
    func removeAll()
}
