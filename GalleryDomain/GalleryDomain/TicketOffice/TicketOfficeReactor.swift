//
//  TicketOfficeReactor.swift
//  GalleryDomain
//  Created by 장공의 on 26/03/2019.
//  Copyright © 2019 gonini. All rights reserved.
//

import Foundation

import ReactorKit
import RxSwift

final public class TicketOfficeReactor: Reactor, ViewingTimeStream {
    public let initialState: State
    
    var viewingTimeStream: BehaviorSubject<GlobalStreamItem<ViewingTime>>?
    
    private static let id = "TicketOfficeReactor"
    
    private var networkStatus: NetworkStatusService
    private var disposeBag = DisposeBag()
    
    public init(globalStream: GlobalStreamService, networkStatus: NetworkStatusService) {
        initialState = State.initialState
        self.networkStatus = networkStatus
        setUpViewingTimeStream(globalStream,
                               itemId: TicketOfficeReactor.id,
                               initialViewingTime: initialState.viewingTime)
    }
    
    public struct State {
        public var viewingTimeLimit: ViewingTimeRange
        public var propagetedViewingTime: ViewingTime
        public var viewingTime: ViewingTime
        public var connectionStatus: Bool
    }
    
    public enum Action {
        case selectTickets(with: ViewingTime)
        case useTickets
    }
    
    public enum Mutation {
        case updateViewingTime(with: ViewingTime)
        case propagateViewingTime
        case setPropagatedTime(with: ViewingTime)
        case networkConnectionFailed
    }
    
    public func transform(mutation: Observable<Mutation>) -> Observable<Mutation> {
        let propagated = viewingTimeStream!
            .filter { $0.id != TicketOfficeReactor.id }
            .map { $0.item }
            .observeOn(MainScheduler.asyncInstance)
            .distinctUntilChanged()
            .flatMap { time in return Observable<Mutation>.concat([
                .just(Mutation.setPropagatedTime(with: time)),
                .just(Mutation.updateViewingTime(with: time))
                ])}
        
        return .merge(mutation, propagated, networkConnectionFailed())
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
            propagateViewingTime(itemId: TicketOfficeReactor.id,
                                 with: newState.viewingTime)
            return newState
        case let .setPropagatedTime(with):
            newState.propagetedViewingTime = with
            return newState
        case .networkConnectionFailed:
            newState.connectionStatus = false
            return newState
        }
    }
}

fileprivate extension TicketOfficeReactor {
    private func networkConnectionFailed() -> Observable<Mutation> {
        return networkStatus.observeNetworkStatus(interval: 1.0)
            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
            .filter { $0 == .none }
            .map { _ in Mutation.networkConnectionFailed }
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

fileprivate extension TicketOfficeReactor.State {
    static let initialState: TicketOfficeReactor.State = .init(
        viewingTimeLimit: ViewingTimeRange.basic,
        propagetedViewingTime: ViewingTimeRange.defaultMinTime,
        viewingTime: ViewingTimeRange.defaultMinTime,
        connectionStatus: true)
}
