//
//  Atomic.swift
//  GalleryDomain
//
//  Created by 장공의 on 31/03/2019.
//  Copyright © 2019 gonini. All rights reserved.
//  https://www.objc.io/blog/2018/12/18/atomic-variables/
//

import Foundation

final class Atomic<A> {
    private let queue = DispatchQueue(label: "Atomic serial queue")
    private var _value: A
    init(_ value: A) {
        self._value = value
    }
    
    var value: A {
        get {
            return queue.sync { self._value }
        }
    }
    
    func mutate(_ transform: (inout A) -> ()) {
        queue.sync {
            transform(&self._value)
        }
    }
}
