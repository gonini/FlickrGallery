//
//  LogService.swift
//  GalleryDomain
//
//  Created by 장공의 on 02/04/2019.
//  Copyright © 2019 gonini. All rights reserved.
//

import Foundation
import os

public protocol LogService {
    func log(_ contant: String, level: LogLevel)
    func log(_ error: Error)
    func log(_ error: Error, _ contant: String)
}

public enum LogLevel {
    case `default`
    case info
    case debug
    case error
    case fault
}

public struct BasicLogger: LogService {
    private static let galleryDomainLog = OSLog(subsystem: "com.gallery_domain", category: "gallery domain error")
    
    public init() { }
    
    public func log(_ contant: String, level: LogLevel) {
        os_log("%{public}@", log: BasicLogger.galleryDomainLog, type: level.osLogLevel, contant)
    }
    
    public func log(_ error: Error) {
        os_log("%{public}@", log: BasicLogger.galleryDomainLog, type: .default, error.localizedDescription)
    }
    
    public func log(_ error: Error, _ contant: String) {
        os_log("%{public}@", log: BasicLogger.galleryDomainLog, type: .default,
               "error: \(error.localizedDescription) contant: \(contant)")
    }
    
    public func log(_ error: Error, _ contant: String, level: LogLevel) {
        os_log("%{public}@", log: BasicLogger.galleryDomainLog, type: level.osLogLevel,
               "error: \(error.localizedDescription) contant: \(contant)")
    }
}

extension LogLevel {
    var osLogLevel: OSLogType {
        switch self {
        case .info:
            return .info
        case .debug:
            return .debug
        case .error:
            return .error
        case .fault:
            return .fault
        default:
            return .default
        }
    }
}
