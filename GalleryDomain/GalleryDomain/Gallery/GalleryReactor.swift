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
    private let viewingTimeStream: ReplaySubject<ViewingTime>
    private let galleyImageStream: Observable<Data>? = nil
    var disposeBag = DisposeBag()
    
    public init(viewingTimeStream: ReplaySubject<ViewingTime>) {
        initialState = State(
            viewingTimeLimit: ViewingTimeRange.basic,
            propagetedViewingTime: ViewingTimeRange.defaultMinTime,
            viewingTime: ViewingTimeRange.defaultMinTime,
            artImage: nil
        )
        self.viewingTimeStream = viewingTimeStream
        
        var model = GalleryFeedModel()
        
        model.galleryFeeds
        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
            .subscribe(onNext: { (feeds) in
                _ = "A"
            }, onError: { (error) in
                _ = "A"
            })
        .disposed(by: disposeBag)
        
    }
    
    public struct State {
        public var viewingTimeLimit: ViewingTimeRange
        public var propagetedViewingTime: ViewingTime
        public var viewingTime: ViewingTime
        public var artImage: Data?
    }
    
    public enum Action {
        case exchangeTickets(with: ViewingTime)
    }
    
    public enum Mutation {
        case setViewingTime(with: ViewingTime)
        case propagateViewingTime
        case setPropagatedTime(with: ViewingTime)
    }
    
    public func transform(mutation: Observable<Mutation>) -> Observable<Mutation> {
        return .merge(mutation, propagatedTime())
    }
    
    public func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case let .exchangeTickets(with):
            return .concat([
                .just(Mutation.setViewingTime(with: with)),
                .just(Mutation.propagateViewingTime)
                ])
        }
    }
    
    public func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        switch mutation {
        case let .setViewingTime(with):
            newState.viewingTime = with
            return newState
        case .setPropagatedTime(let with):
            guard newState.viewingTime != with else { return newState }
            newState.propagetedViewingTime = with
            return newState
        case .propagateViewingTime:
            viewingTimeStream.onNext(newState.viewingTime)
            return newState
        }
    }
    
    private func propagatedTime() -> Observable<Mutation> {
        return viewingTimeStream
            .observeOn(MainScheduler.asyncInstance)
            .distinctUntilChanged()
            .flatMap { time in return Observable<Mutation>.concat([
                .just(Mutation.setPropagatedTime(with: time)),
                .just(Mutation.setViewingTime(with: time))
                ])}
    }
}
