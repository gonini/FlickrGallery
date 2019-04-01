//
//  ImageDownloadService.swift
//  FlickerService
//
//  Created by 장공의 on 01/04/2019.
//  Copyright © 2019 gonini. All rights reserved.
//

import Foundation
import RxSwift
import RxAlamofire
import GalleryDomain

public struct ImageDownloadService: FileDownloadService {
    public init() { }
    
    public func load(url: URL) -> Observable<Data> {
        return RxAlamofire.request(.get, url)
            .responseData()
            .filter { (response, _) -> Bool in response.statusCode == 200 }
            .retry(1)
            .catchError(Observable.error)
            .map { $0.1 }
    }
}
