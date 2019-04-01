//
//  String+Date.swift
//  GalleryDomain
//
//  Created by 장공의 on 31/03/2019.
//  Copyright © 2019 gonini. All rights reserved.
//

import Foundation

extension String {
    static let flickerDateFormatter: DateFormatter = {
        var ret = DateFormatter()
        ret.dateFormat = "yyyy-MM-dd'T'HH:mm:ssxxxxx"
        return ret
    }()
    
    func toFlickerFormatDate() -> Date {
        return String.flickerDateFormatter.date(from: self)!
    }
}
