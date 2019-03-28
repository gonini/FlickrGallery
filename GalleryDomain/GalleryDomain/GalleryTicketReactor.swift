//
//  GalleryTicketReactor.swift
//  GalleryDomain
//asdnmaksjdnaksdblahsjkbdfahjskdfbashkljdfgbkasdajhsdfvkasgf
//  Created by 장공의 on 26/03/2019.
//  Copyright © 2019 gonini. All rights reserved.
//

import Foundation

import ReactorKit
import RxSwift

final public class GalleryTicketReactor: Reactor {
    public init() { }
    
    public enum Action {
        case enterTicketOffice
        case selectTickets(with: TimeInterval)
        case enterGallery
    }
    
    public enum Mutation {
        case initState
        case setViewingTime(with: TimeInterval)
        case buyTickets
    }
    
    public struct State {
        public var viewingTimeLimit: ViewingTimeRange
        public var viewingTime: TimeInterval
    }
    
    public let initialState = State(viewingTimeLimit: ViewingTimeRange.basic,
                             viewingTime: ViewingTimeRange.defaultMinTime)
    
    public func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .enterTicketOffice:
            return .empty()
        case let .selectTickets(time):
            return .just(Mutation.setViewingTime(with: time))
        case .enterGallery:
            return .just(Mutation.buyTickets)
        
        }
    }
    
    public func reduce(state: State, mutation: Mutation) -> State {
        switch mutation {
        case .initState:
            return initialState
        case let .setViewingTime(with):
            var newState = state
            newState.viewingTime = with
            return newState
        case .buyTickets:
            return state
        }
    }
}

public struct ViewingTimeRange {
    public let minTime: TimeInterval
    public let maxTime: TimeInterval
}

fileprivate extension ViewingTimeRange {
    fileprivate static let defaultMinTime = 1.0
    fileprivate static let defaultMaxTime = 10.0
    
    fileprivate static var basic: ViewingTimeRange {
        return ViewingTimeRange(minTime: ViewingTimeRange.defaultMinTime,
                                maxTime: ViewingTimeRange.defaultMaxTime)
    }
}
