//
//  GlobalStream.swift
//  GalleryDomain
//
//  Created by 장공의 on 31/03/2019.
//  Copyright © 2019 gonini. All rights reserved.
//

import Foundation
import RxSwift

public class GlobalStream {
    private var streamTable = [StreamId: Any]()
    
    public init() { }
    
    func getAndCreate<T>(id: StreamId, defaultValue: GlobalStreamItem<T>) -> BehaviorSubject<GlobalStreamItem<T>> {
        if streamTable.keys.contains(id) {
            return streamTable[id] as! BehaviorSubject<GlobalStreamItem<T>>
        }
        let ret = BehaviorSubject<GlobalStreamItem<T>>(value: defaultValue)
        streamTable[id] = ret
        return ret
    }
    
    deinit {
        
    }
}

public enum StreamId {
    case vieingTime
}

struct GlobalStreamItem<T> {
    var id: String
    var item: T
}
