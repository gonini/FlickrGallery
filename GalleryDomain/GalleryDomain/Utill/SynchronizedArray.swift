//
//  SynchronizedArray.swift
//  GalleryDomain
//
//  Created by 장공의 on 31/03/2019.
//  Copyright © 2019 gonini. All rights reserved.
//  https://medium.com/@mohit.bhalla/thread-safety-in-ios-swift-7b75df1d2ba6
//

import Foundation

public class SynchronizedArray<Element> {
    private let queue = DispatchQueue(label: "goni_synchronizedArray", attributes: .concurrent)
    private var array = [Element]()
    
    public init() { }
    
    public convenience init(_ array: [Element]) {
        self.init()
        self.array = array
    }
}

public extension SynchronizedArray {
    var first: Element? {
        var result: Element?
        queue.sync { result = self.array.first }
        return result
    }
    
    var last: Element? {
        var result: Element?
        queue.sync { result = self.array.last }
        return result
    }
    
    var count: Int {
        var result = 0
        queue.sync { result = self.array.count }
        return result
    }
    
    var isEmpty: Bool {
        var result = false
        queue.sync { result = self.array.isEmpty }
        return result
    }
}

public extension SynchronizedArray {
    func first(where predicate: (Element) -> Bool) -> Element? {
        var result: Element?
        queue.sync { result = self.array.first(where: predicate) }
        return result
    }
}

public extension SynchronizedArray {
    func append(_ element: Element) {
        queue.async(flags: .barrier) {
            self.array.append(element)
        }
    }
    
    func removeFirst() {
        queue.async(flags: .barrier) {
            if !self.array.isEmpty {
                self.array.removeFirst()
            }
        }
    }
}
