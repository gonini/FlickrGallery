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
    private static let defaultAnmtnTime = 1.0
    public let initialState: State
    
    private let viewingTimeStream: BehaviorSubject<GlobalStreamItem<ViewingTime>>
    private let galleyImageStream = BehaviorSubject<GalleyImage?>(value: nil)
    private let galleyFeed: SynchronizedArray<URL> = .init()
    private let downloadService: FileDownloadService
    
    private var timerDisposable: Disposable?
    private var disposeBag = DisposeBag()
    
    public init(globalStream: GlobalStream, downloadService: FileDownloadService) {
        initialState = State(
            viewingTimeLimit: ViewingTimeRange.basic,
            propagetedViewingTime: nil,
            viewingTime: ViewingTimeRange.defaultMinTime,
            galleyImage: .init(image: nil, imswpAnmtnTime: 0)
        )
        
        let defaultViewingTime =
            GlobalStreamItem<ViewingTime>(id: GalleryReactor.id,
                                          item: initialState.viewingTime)
        
        self.viewingTimeStream = globalStream
            .getAndCreate(id: StreamId.vieingTime,
                          defaultValue: defaultViewingTime)
        
        self.downloadService = downloadService
        
        galleryImageUrls()
            .subscribe(onNext: { self.galleyFeed.append($0) })
            .disposed(by: disposeBag)
    }
    
    public struct State {
        public var viewingTimeLimit: ViewingTimeRange
        public var propagetedViewingTime: ViewingTime?
        public var viewingTime: ViewingTime
        public var galleyImage: GalleyImage
    }
    
    public enum Action {
        case exchangeTickets(with: ViewingTime)
    }
    
    public enum Mutation {
        case setViewingTime(with: ViewingTime)
        case propagateViewingTime
        case setPropagatedTime(with: ViewingTime)
        case setArtImage(with: GalleyImage)
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
            newState.galleyImage = with
            return newState
        case .applyImageSlideTime:
            chnageViewingTime(newState.viewingTime,
                              anmtnTime: GalleryReactor.defaultAnmtnTime)
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
    
    private func chnageViewingTime(_ with: TimeInterval, anmtnTime: TimeInterval) {
        timerDisposable?.dispose()
        timerDisposable = Observable<Int>.interval(with + anmtnTime,
                                                   scheduler: ConcurrentDispatchQueueScheduler(qos: .background))
            .startWith(0)
            .filter { _ in !self.galleyFeed.isEmpty }
            .map { _ in
                let ret = self.galleyFeed.first
                self.galleyFeed.removeFirst()
                return ret
            }
            .flatMap { Observable.from(optional: $0) }
            .debug()
            .flatMap(downloadService.load)
            .map { GalleyImage(image: $0, imswpAnmtnTime: anmtnTime) }
            .subscribe(onNext: { [weak self] in
                guard let `self` = self else { return }
                self.galleyImageStream.onNext($0)
            })
    }
}

public struct GalleyImage {
    public var image: Data?
    public var imswpAnmtnTime: TimeInterval
    
    public static func == (lhs: GalleyImage,
                           rhs: GalleyImage) -> Bool {
        return lhs.image == rhs.image &&
            lhs.imswpAnmtnTime == rhs.imswpAnmtnTime
    }
}
