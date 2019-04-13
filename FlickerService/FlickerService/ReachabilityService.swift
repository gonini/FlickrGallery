//
//  ReachabilityService.swift
//  FlickerService
//
//  Created by 장공의 on 01/04/2019.
//  Copyright © 2019 gonini. All rights reserved.
//

import Foundation
import GalleryDomain

import Alamofire
import RxSwift

public struct ReachabilityService: NetworkStatusService {
    public func observeNetworkStatus() -> Observable<NetworkStatus> {
        return .empty()
    }
    
    public init() { }
    
    public func observeNetworkStatus(interval: TimeInterval) -> Observable<NetworkStatus> {
        let manager = NetworkReachabilityManager(
            host: "https://www.flickr.com/services"
        )
        
        return Observable<Int>
            .interval(interval, scheduler: ConcurrentDispatchQueueScheduler(qos: .background))
            .map { _ in manager?.networkReachabilityStatus }
            .map { status -> NetworkStatus in
                guard let status = status else { return .none }
                if status == .notReachable || status == .unknown {
                    return .none
                }
                return .reachable
            }.distinctUntilChanged()
    }
}
