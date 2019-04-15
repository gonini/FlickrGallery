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

final public class GalleryReactor: Reactor, ViewingTimeStream {
    public let initialState: State
    
    var viewingTimeStream: BehaviorSubject<GlobalStreamItem<ViewingTime>>?
    
    private static let streamId = "GalleryReactor"
    private static let galleryImageFadeTime = 1.0
    private static let feedRefreshInterval = 3.0
    
    private let imageStream = BehaviorSubject<GalleyImage?>(value: nil)
    private let feedBuffer = FeedBuffer<UrlSelectionStrategy>()
    private let feedStrategy = UrlSelectionStrategy()
    private let downloadService: FileDownloadService
    private let feedService: GalleryFeedService
    private let logger: LogService
    
    private var timerDisposable: Disposable?
    private var feedsDisposable: Disposable?
    private var disposeBag = DisposeBag()
    
    public init(globalStream: GlobalStreamService,
                downloadService: FileDownloadService,
                feedService: GalleryFeedService,
                logger: LogService) {
        self.downloadService = downloadService
        self.feedService = feedService
        self.logger = logger
        initialState = State.initialState
        feedBuffer.feedSelection = feedStrategy
        setUpViewingTimeStream(globalStream,
                               itemId: GalleryReactor.streamId,
                               initialViewingTime: initialState.viewingTime)
    }
    
    public struct State {
        public var viewingTimeLimit: ViewingTimeRange
        public var propagetedViewingTime: ViewingTime?
        public var viewingTime: ViewingTime
        public var galleyImage: GalleyImage
    }
    
    public enum Action {
        case exchangeTickets(with: ViewingTime)
        case willAppearScreen
        case didAppearScreen
        case willDisAppearScreen
        case didDisAppearScreen
    }
    
    public enum Mutation {
        case setViewingTime(with: ViewingTime)
        case propagateViewingTime
        case setPropagatedTime(with: ViewingTime)
        case setArtImage(with: GalleyImage)
        case applyViewingTime
        case observeFeeds
        case clearFeeds
    }
    
    public func transform(mutation: Observable<Mutation>) -> Observable<Mutation> {
        let artImageMutation = imageStream
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
                .just(.applyViewingTime)
                ])
        case .willAppearScreen:
            return .just(.observeFeeds)
        case .willDisAppearScreen:
            return .just(.clearFeeds)
        default:
            return .empty()
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
            propagateViewingTime(itemId: GalleryReactor.streamId,
                                 with: newState.viewingTime)
            return newState
        case let .setArtImage(with):
            newState.galleyImage = with
            return newState
        case .applyViewingTime:
            applyViewingTime(newState.viewingTime,
                             anmtnTime: GalleryReactor.galleryImageFadeTime)
            return newState
        case .observeFeeds:
            observeFeeds(self.feedService)
            return newState
        case .clearFeeds:
            clearFeeds()
            return newState
        }
    }
}

fileprivate extension GalleryReactor {
    private func clearFeeds() {
        timerDisposable?.dispose()
        feedsDisposable?.dispose()
        feedBuffer.removeAll()
        feedStrategy.removeAll()
    }
    
    private func observeFeeds(_ feedService: GalleryFeedService) {
        feedsDisposable = feedService.observeFeeds(refreshInterval: GalleryReactor.feedRefreshInterval)
            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
            .map { URL(string: $0.imageUrl)! }
            .subscribe(onNext: { [weak self] url in
                guard let `self` = self else { return }
                self.feedBuffer.append(url)
            }, onError: { [weak self] error in
                guard let `self` = self else { return }
                self.logger.log(error)
            })
    }

    private func propagatedTime() -> Observable<Mutation> {
        return viewingTimeStream!
            .filter { $0.streamId != GalleryReactor.streamId }
            .map { $0.item }
            .observeOn(MainScheduler.asyncInstance)
            .distinctUntilChanged()
            .flatMap { time in return Observable<Mutation>.concat([
                .just(.setPropagatedTime(with: time)),
                .just(.setViewingTime(with: time)),
                .just(.applyViewingTime)
                ])
            }
    }
    
    private func applyViewingTime(_ with: TimeInterval, anmtnTime: TimeInterval) {
        timerDisposable?.dispose()
        let userScheduling =
            Observable<Int>.interval(with + anmtnTime,
                                     scheduler: ConcurrentDispatchQueueScheduler(qos: .background))
        
        let firstImageScheduler = Observable<Int>
            .interval(0.1, scheduler: ConcurrentDispatchQueueScheduler(qos: .background))
            .take(1)
        
        timerDisposable = Observable.merge(userScheduling, firstImageScheduler)
            .map { [weak self] _ in
                guard let `self` = self else { return nil }
                return self.feedBuffer.currentFeed
            }
            .flatMap { Observable.from(optional: $0) }
            .flatMap(downloadService.load)
            .map { GalleyImage(image: $0, imswpAnmtnTime: anmtnTime) }
            .subscribe(onNext: { [weak self] in
                guard let `self` = self else { return }
                self.imageStream.onNext($0)
                }, onError: { [weak self] error in
                    guard let `self` = self else { return }
                    self.logger.log(error, "이미지 다운로드 실패")
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

fileprivate extension GalleryReactor.State {
    static let initialState: GalleryReactor.State = .init(
        viewingTimeLimit: ViewingTimeRange.basic,
        propagetedViewingTime: nil,
        viewingTime: ViewingTimeRange.defaultMinTime,
        galleyImage: .init(image: nil, imswpAnmtnTime: 0))
}
