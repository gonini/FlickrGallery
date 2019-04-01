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
    func getAndCreate<T>(id: StreamId, defaultValue: GlobalStreamItem<T>) -> BehaviorSubject<GlobalStreamItem<T>>
}

public enum StreamId {
    case vieingTime
}

public struct GlobalStreamItem<T> {
    var id: String
    var item: T
}

public class TemporaryGlobalStream: GlobalStreamService {
    private var streamTable = [StreamId: Any]()
    
    public init() { }
    
    // 에러 처리 전혀 안되어 있음..
    // 여유 시간 생기면 수정...
    public func getAndCreate<T>(id: StreamId, defaultValue: GlobalStreamItem<T>) ->
        BehaviorSubject<GlobalStreamItem<T>> {
        if streamTable.keys.contains(id) {
            return streamTable[id] as! BehaviorSubject<GlobalStreamItem<T>>
        }
        let ret = BehaviorSubject<GlobalStreamItem<T>>(value: defaultValue)
        streamTable[id] = ret
        return ret
    }
}
