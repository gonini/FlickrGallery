//
//  GlobalStreamService.swift
//  GalleryDomain
//
//  Created by 장공의 on 01/04/2019.
//  Copyright © 2019 gonini. All rights reserved.
//

import Foundation
import RxSwift

public protocol GlobalStreamService {
    func getAndCreate<T>(streamId: StreamId, defaultValue: GlobalStreamItem<T>) -> BehaviorSubject<GlobalStreamItem<T>>
}

public enum StreamId {
    case vieingTime
}

public struct GlobalStreamItem<T> {
    var streamId: String
    var item: T
}

public class TemporaryGlobalStream: GlobalStreamService {
    private var streamTable = [StreamId: Any]()
    
    public init() { }
    
    // 에러 처리 전혀 안되어 있음..
    // 여유 시간 생기면 수정...
    public func getAndCreate<T>(streamId: StreamId, defaultValue: GlobalStreamItem<T>) ->
        BehaviorSubject<GlobalStreamItem<T>> {
            guard streamTable.keys.contains(streamId) else {
                let ret = BehaviorSubject<GlobalStreamItem<T>>(value: defaultValue)
                streamTable[streamId] = ret
                return ret
            }
        
            if let ret = streamTable[streamId] as? BehaviorSubject<GlobalStreamItem<T>> {
                return ret
            }
            fatalError("invalid stream id as an argument.")
    }
}
