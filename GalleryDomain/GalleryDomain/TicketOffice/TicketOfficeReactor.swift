//
//  TicketOfficeReactor.swift
//  GalleryDomain
//  Created by 장공의 on 26/03/2019.
//  Copyright © 2019 gonini. All rights reserved.
//

import Foundation

import ReactorKit
import RxSwift

public typealias ViewingTime = TimeInterval

final public class TicketOfficeReactor: Reactor {
    private static let id = "TicketOfficeReactor"
    public let initialState: State
    private let viewingTimeStream: BehaviorSubject<GlobalStreamItem<ViewingTime>>
    
    public init(globalStream: GlobalStream) {
        initialState = State(
            viewingTimeLimit: ViewingTimeRange.basic,
            propagetedViewingTime: ViewingTimeRange.defaultMinTime,
            viewingTime: ViewingTimeRange.defaultMinTime
        )
        
        let defaultViewingTime =
            GlobalStreamItem<ViewingTime>(id: TicketOfficeReactor.id, item: initialState.viewingTime)
        
        self.viewingTimeStream = globalStream
            .getAndCreate(id: StreamId.vieingTime,
                          defaultValue: defaultViewingTime)
    }
    
    public struct State {
        public var viewingTimeLimit: ViewingTimeRange
        public var propagetedViewingTime: ViewingTime
        public var viewingTime: ViewingTime
    }
    
    public enum Action {
        case selectTickets(with: ViewingTime)
        case useTickets
    }
    
    public enum Mutation {
        case updateViewingTime(with: ViewingTime)
        case propagateViewingTime
        case setPropagatedTime(with: ViewingTime)
    }
    
    public func transform(mutation: Observable<Mutation>) -> Observable<Mutation> {
        let propagated = viewingTimeStream
            .filter { $0.id != TicketOfficeReactor.id }
            .map { $0.item }
            .observeOn(MainScheduler.asyncInstance)
            .distinctUntilChanged()
            .flatMap { time in return Observable<Mutation>.concat([
                .just(Mutation.setPropagatedTime(with: time)),
                .just(Mutation.updateViewingTime(with: time))
                ])}
        
        return .merge(mutation, propagated)
    }
    
    public func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case let .selectTickets(time):
            return .just(.updateViewingTime(with: time))
        case .useTickets:
            return .just(.propagateViewingTime)
        }
    }
    
    public func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        switch mutation {
        case let .updateViewingTime(with):
            newState.viewingTime = with
            return newState
        case .propagateViewingTime:
            viewingTimeStream.onNext(
                .init(id: TicketOfficeReactor.id,
                      item: newState.viewingTime)
            )
            return newState
        case let .setPropagatedTime(with):
            guard newState.viewingTime != with else { return newState }
            newState.propagetedViewingTime = with
            return newState
        }
    }
    
    private func createViewingTimeItem(_ with: ViewingTime) -> GlobalStreamItem<ViewingTime> {
        return .init(id: TicketOfficeReactor.id,
              item: with)
    }
}

public struct ViewingTimeRange: Equatable {
    public let minTime: ViewingTime
    public let maxTime: ViewingTime
    
    public static func == (lhs: ViewingTimeRange,
                           rhs: ViewingTimeRange) -> Bool {
        return lhs.minTime == rhs.minTime &&
            lhs.maxTime == rhs.maxTime
    }
}

extension ViewingTimeRange {
    static let defaultMinTime = 1.0
    static let defaultMaxTime = 10.0
    
    static var basic: ViewingTimeRange {
        return .init(minTime: ViewingTimeRange.defaultMinTime,
                                maxTime: ViewingTimeRange.defaultMaxTime)
    }
}

public extension ViewingTime {
    public static let `default`: ViewingTime = 1
}
