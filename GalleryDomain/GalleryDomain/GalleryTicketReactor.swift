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
    public let initialState: State
    
    public init() {
        self.initialState = State(
            viewingTimeLimit: ViewingTimeRange.basic,
            viewingTime: ViewingTimeRange.defaultMinTime
        )
    }
    
    public enum Action {
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
    
    public func mutate(action: Action) -> Observable<Mutation> {
        switch action {
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

public struct ViewingTimeRange: Equatable {
    public let minTime: TimeInterval
    public let maxTime: TimeInterval
    
    public static func == (lhs: ViewingTimeRange,
                           rhs: ViewingTimeRange) -> Bool {
        return lhs.minTime == rhs.minTime &&
            lhs.maxTime == rhs.maxTime
    }
}

fileprivate extension ViewingTimeRange {
    fileprivate static let defaultMinTime = 1.0
    fileprivate static let defaultMaxTime = 10.0
    
    fileprivate static var basic: ViewingTimeRange {
        return ViewingTimeRange(minTime: ViewingTimeRange.defaultMinTime,
                                maxTime: ViewingTimeRange.defaultMaxTime)
    }
}
