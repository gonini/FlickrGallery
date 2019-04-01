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
        .catchError(Observable.error)
        .filter { (res, _) -> Bool in res.statusCode == 200 }
        .map { (_, data) -> Data in return data }
    }
}
