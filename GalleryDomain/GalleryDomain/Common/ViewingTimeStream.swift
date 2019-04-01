//
//  ViewingTimeStream.swift
//  GalleryDomain
//
//  Created by 장공의 on 02/04/2019.
//  Copyright © 2019 gonini. All rights reserved.
//

import Foundation
import RxSwift

public typealias ViewingTime = TimeInterval

protocol ViewingTimeStream: class {
    var viewingTimeStream: BehaviorSubject<GlobalStreamItem<ViewingTime>>? { get set }
}

extension ViewingTimeStream {
    func setUpViewingTimeStream(_ globalStream: GlobalStreamService,
                                itemId: String,
                                initialViewingTime: ViewingTime) {
        self.viewingTimeStream = globalStream.getAndCreate(
            id: StreamId.vieingTime,
            defaultValue: .init(id: itemId, item: initialViewingTime))
    }
    
    func propagateViewingTime(itemId: String, with: ViewingTime) {
        viewingTimeStream?.onNext(
            .init(id: itemId,
                  item: with)
        )
    }
}
