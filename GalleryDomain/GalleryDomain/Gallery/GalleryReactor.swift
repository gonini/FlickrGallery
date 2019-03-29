//
//  GalleryReactor.swift
//  GalleryDomain
//
//  Created by 장공의 on 29/03/2019.
//  Copyright © 2019 gonini. All rights reserved.
//

import Foundation

import ReactorKit
import RxSwift

final public class GalleryReactor: Reactor {
    public let initialState: State
    
    public init() {
        initialState = State()
    }
    
    public enum Action {
    }
    
    public enum Mutation {
    }
    
    public func mutate(action: Action) -> Observable<Mutation> {
        return .empty()
    }
    
    public func reduce(state: State, mutation: Mutation) -> State {
        return state
    }
    
    public struct State { }
}
