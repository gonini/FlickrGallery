//
//  UrlSelectionStrategy.swift
//  GalleryDomain
//
//  Created by 장공의 on 15/04/2019.
//  Copyright © 2019 gonini. All rights reserved.
//

import Foundation

// Rule of UrlSelectionStrategy
// 1. 최초  보여줄 이미지 없을시 임의 이미지 사용
// 2. fliker api를 통해 이미지를 받아온 경우 n개는 삭제하지 않고 유지
// 3. 보여줄 이미지 없을시 2번에서 유지한 이미지를 반환
class UrlSelectionStrategy: FeedSelectionStrategy {
    private static let dummyUrl = URL(string: "https://source.unsplash.com/random/600x300")
    private static let feedRecyclingSize = 40
    
    private let recyclingSize: Int
    private let recyclingBuffer: SynchronizedArray<URL>
    
    convenience init() {
        self.init(urlRecyclingSize: UrlSelectionStrategy.feedRecyclingSize)
    }
    
    init(urlRecyclingSize: Int) {
        recyclingSize = urlRecyclingSize
        recyclingBuffer = .init()
    }
    
    func selectFeed(_ feeds: SynchronizedArray<URL>) -> URL? {
        if let newFeed = feeds.first {
            updateRecycling(with: newFeed)
            feeds.removeFirst()
            return newFeed
        }
        
        if let recyclingFeed = recyclingBuffer.curFeed {
            return recyclingFeed
        }
 
        return UrlSelectionStrategy.dummyUrl
    }
    
    func removeAll() {
        recyclingBuffer.removeAll()
    }
    
    private func updateRecycling(with url: URL) {
        if recyclingBuffer.count > recyclingSize {
            recyclingBuffer.removeFirst()
        }
        recyclingBuffer.append(url)
    }
}

fileprivate extension SynchronizedArray where Element == URL {
    var curFeed: URL? {
        get {
            guard !self.isEmpty else {
                return nil
            }
            
            let randumIdx = Int(arc4random_uniform(UInt32(self.count)))
            return self[randumIdx]
        }
    }
}
