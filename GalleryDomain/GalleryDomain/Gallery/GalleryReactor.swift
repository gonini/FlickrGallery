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
    private static let id = "GalleryReactor"
    public let initialState: State
    
    private let viewingTimeStream: BehaviorSubject<GlobalStreamItem<ViewingTime>>
    private let galleyImageStream = BehaviorSubject<Data?>(value: nil)
    private let galleyImageQueue: SynchronizedArray<URL> = .init()
    private let downloadService: FileDownloadService
    
    private var timerDisposable: Disposable?
    private var disposeBag = DisposeBag()
    
    public init(globalStream: GlobalStream, downloadService: FileDownloadService) {
        initialState = State(
            viewingTimeLimit: ViewingTimeRange.basic,
            propagetedViewingTime: nil,
            viewingTime: ViewingTimeRange.defaultMinTime,
            artImage: nil
        )
        
        let defaultViewingTime =
            GlobalStreamItem<ViewingTime>(id: GalleryReactor.id,
                                          item: initialState.viewingTime)
        
        self.viewingTimeStream = globalStream
            .getAndCreate(id: StreamId.vieingTime,
                          defaultValue: defaultViewingTime)
        
        self.downloadService = downloadService
        
        galleryImageUrls()
            .subscribe(onNext: { self.galleyImageQueue.append($0) })
            .disposed(by: disposeBag)
    }
    
    public struct State {
        public var viewingTimeLimit: ViewingTimeRange
        public var propagetedViewingTime: ViewingTime?
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
        case setArtImage(with: Data)
        case applyImageSlideTime
    }
    
    public func transform(mutation: Observable<Mutation>) -> Observable<Mutation> {
        let artImageMutation = galleyImageStream
            .flatMap { Observable.from(optional: $0) }
            .map(Mutation.setArtImage)
        
        return .merge(mutation, artImageMutation, propagatedTime())
    }
    
    public func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case let .exchangeTickets(with):
            return .concat([
                .just(.setViewingTime(with: with)),
                .just(.propagateViewingTime),
                .just(.applyImageSlideTime)
                ])
        }
    }
    
    public func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        switch mutation {
        case let .setViewingTime(with):
            newState.viewingTime = with
            return newState
        case let .setPropagatedTime(with):
            newState.propagetedViewingTime = with
            return newState
        case .propagateViewingTime:
            viewingTimeStream.onNext(
                .init(id: GalleryReactor.id,
                      item: newState.viewingTime)
            )
            return newState
        case let .setArtImage(with):
            newState.artImage = with
            return newState
        case .applyImageSlideTime:
            chnageViewingTime(newState.viewingTime)
            return newState
        }
    }
    
    private func propagatedTime() -> Observable<Mutation> {
        return viewingTimeStream
            .filter { $0.id != GalleryReactor.id }
            .map { $0.item }
            .observeOn(MainScheduler.asyncInstance)
            .distinctUntilChanged()
            .flatMap { time in return Observable<Mutation>.concat([
                .just(.setPropagatedTime(with: time)),
                .just(.setViewingTime(with: time)),
                .just(.applyImageSlideTime)
                ])}
    }
        
    private func galleryImageUrls() -> Observable<URL> {
        var model = GalleryFeedModel()
        return model.galleryFeeds
            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
            .do(onNext: { (feedItem) in
                print(feedItem.title)
            })
            .map { URL(string: $0.imageUrl)! }
    }
    
    private func chnageViewingTime(_ with: TimeInterval) {
        timerDisposable?.dispose()
        timerDisposable = Observable<Int>.interval(with, scheduler: ConcurrentDispatchQueueScheduler(qos: .background))
            .filter { _ in !self.galleyImageQueue.isEmpty }
            .map { _ in
                let ret = self.galleyImageQueue.first
                self.galleyImageQueue.removeFirst()
                return ret
            }
            .flatMap { Observable.from(optional: $0) }
            .flatMap(downloadService.load)
            .subscribe(onNext: { [weak self] data in
                guard let `self` = self else { return }
                self.galleyImageStream.onNext(data)
            })
    }
    
}
