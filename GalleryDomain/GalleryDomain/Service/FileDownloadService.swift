//
//  ImageDownloader.swift
//  GalleryDomain
//
//  Created by 장공의 on 01/04/2019.
//  Copyright © 2019 gonini. All rights reserved.
//

import Foundation
import RxSwift

public protocol FileDownloadService {
    func load(url: URL) -> Observable<Data>
}
