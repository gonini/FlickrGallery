//
//  NetworkStatusService.swift
//  GalleryDomain
//
//  Created by 장공의 on 01/04/2019.
//  Copyright © 2019 gonini. All rights reserved.
//

import Foundation
import RxSwift

public protocol NetworkStatusService {
    func observeNetworkStatus(interval: TimeInterval) -> Observable<NetworkStatus>
}

public enum NetworkStatus {
    case none
    case reachable
}
