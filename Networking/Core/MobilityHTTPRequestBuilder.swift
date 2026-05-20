//
//  MobilityHTTPRequestBuilder.swift
//  Urban Mobility Explorer
//
//  Created by Newt Ding on 2026/05/19.
//
//  Copyright © 2026 The Hongkong and Shanghai Banking Corporation Limited. All rights reserved.
//

import Alamofire
import Foundation

public final class MobilityHTTPRequestBuilderFactory: RequestBuilderFactory, Sendable {
    private let timeout: TimeInterval

    public init(requestTimeout: TimeInterval = 20) {
        self.timeout = requestTimeout
    }

    public func getNonDecodableBuilder<T>() -> RequestBuilder<T>.Type {
        MobilityHTTPRequestBuilder<T>.self
    }

    public func getBuilder<T: Decodable>() -> RequestBuilder<T>.Type {
        MobilityHTTPDecodableRequestBuilder<T>.self
    }

    func configuredSession(interceptor: RequestInterceptor?) -> Session {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = timeout
        configuration.timeoutIntervalForResource = timeout
        return Session(configuration: configuration, interceptor: interceptor)
    }
}

open class MobilityHTTPRequestBuilder<T: Sendable>: AlamofireRequestBuilder<T>, @unchecked Sendable {
    open override func createAlamofireSession() -> Session {
        let factory = apiConfiguration.requestBuilderFactory as? MobilityHTTPRequestBuilderFactory
            ?? MobilityHTTPRequestBuilderFactory()
        return factory.configuredSession(interceptor: apiConfiguration.interceptor)
    }
}

open class MobilityHTTPDecodableRequestBuilder<T: Decodable & Sendable>: AlamofireDecodableRequestBuilder<T>, @unchecked Sendable {
    open override func createAlamofireSession() -> Session {
        let factory = apiConfiguration.requestBuilderFactory as? MobilityHTTPRequestBuilderFactory
            ?? MobilityHTTPRequestBuilderFactory()
        return factory.configuredSession(interceptor: apiConfiguration.interceptor)
    }
}
