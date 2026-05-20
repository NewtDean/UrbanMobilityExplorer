// APIs.swift
//
// Shared HTTP configuration for multiple OpenAPI services.

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Alamofire

/// Common surface for per-service API configuration instances.
public protocol MobilityAPIConfiguring: AnyObject, Sendable {
    var basePath: String { get set }
    var customHeaders: [String: String] { get set }
    var credential: URLCredential? { get set }
    var requestBuilderFactory: RequestBuilderFactory { get set }
    var apiResponseQueue: DispatchQueue { get set }
    var codableHelper: CodableHelper { get set }
    var successfulStatusCodeRange: Range<Int> { get set }
    var interceptor: RequestInterceptor? { get set }
    var dataResponseSerializer: AnyResponseSerializer<Data> { get set }
    var stringResponseSerializer: AnyResponseSerializer<String> { get set }
}

open class CityBikeAPIConfiguration: @unchecked Sendable, MobilityAPIConfiguring {
    public var basePath: String
    public var customHeaders: [String: String]
    public var credential: URLCredential?
    public var requestBuilderFactory: RequestBuilderFactory
    public var apiResponseQueue: DispatchQueue
    public var codableHelper: CodableHelper
    public var successfulStatusCodeRange: Range<Int>
    public var interceptor: RequestInterceptor?
    public var dataResponseSerializer: AnyResponseSerializer<Data>
    public var stringResponseSerializer: AnyResponseSerializer<String>

    public init(
        basePath: String = "https://api.citybik.es/v2",
        customHeaders: [String: String] = [:],
        credential: URLCredential? = nil,
        requestBuilderFactory: RequestBuilderFactory = AlamofireRequestBuilderFactory(),
        apiResponseQueue: DispatchQueue = .main,
        codableHelper: CodableHelper = CodableHelper(),
        successfulStatusCodeRange: Range<Int> = 200..<300,
        interceptor: RequestInterceptor? = nil,
        dataResponseSerializer: AnyResponseSerializer<Data> = AnyResponseSerializer(DataResponseSerializer()),
        stringResponseSerializer: AnyResponseSerializer<String> = AnyResponseSerializer(StringResponseSerializer())
    ) {
        self.basePath = basePath
        self.customHeaders = customHeaders
        self.credential = credential
        self.requestBuilderFactory = requestBuilderFactory
        self.apiResponseQueue = apiResponseQueue
        self.codableHelper = codableHelper
        self.successfulStatusCodeRange = successfulStatusCodeRange
        self.interceptor = interceptor
        self.dataResponseSerializer = dataResponseSerializer
        self.stringResponseSerializer = stringResponseSerializer
    }

    public static let shared = CityBikeAPIConfiguration()
}

open class OpenMeteoAPIConfiguration: @unchecked Sendable, MobilityAPIConfiguring {
    public var basePath: String
    public var customHeaders: [String: String]
    public var credential: URLCredential?
    public var requestBuilderFactory: RequestBuilderFactory
    public var apiResponseQueue: DispatchQueue
    public var codableHelper: CodableHelper
    public var successfulStatusCodeRange: Range<Int>
    public var interceptor: RequestInterceptor?
    public var dataResponseSerializer: AnyResponseSerializer<Data>
    public var stringResponseSerializer: AnyResponseSerializer<String>

    public init(
        basePath: String = "https://api.open-meteo.com/v1",
        customHeaders: [String: String] = [:],
        credential: URLCredential? = nil,
        requestBuilderFactory: RequestBuilderFactory = AlamofireRequestBuilderFactory(),
        apiResponseQueue: DispatchQueue = .main,
        codableHelper: CodableHelper = CodableHelper(),
        successfulStatusCodeRange: Range<Int> = 200..<300,
        interceptor: RequestInterceptor? = nil,
        dataResponseSerializer: AnyResponseSerializer<Data> = AnyResponseSerializer(DataResponseSerializer()),
        stringResponseSerializer: AnyResponseSerializer<String> = AnyResponseSerializer(StringResponseSerializer())
    ) {
        self.basePath = basePath
        self.customHeaders = customHeaders
        self.credential = credential
        self.requestBuilderFactory = requestBuilderFactory
        self.apiResponseQueue = apiResponseQueue
        self.codableHelper = codableHelper
        self.successfulStatusCodeRange = successfulStatusCodeRange
        self.interceptor = interceptor
        self.dataResponseSerializer = dataResponseSerializer
        self.stringResponseSerializer = stringResponseSerializer
    }

    public static let shared = OpenMeteoAPIConfiguration()
}

open class RequestBuilder<T: Sendable>: @unchecked Sendable, Identifiable {
    public var credential: URLCredential?
    public var headers: [String: String]
    public let parameters: [String: any Sendable]?
    public let method: String
    public let URLString: String
    public let requestTask: RequestTask = RequestTask()
    public let requiresAuthentication: Bool
    public let apiConfiguration: any MobilityAPIConfiguring

    public var onProgressReady: ((Progress) -> Void)?

    required public init(
        method: String,
        URLString: String,
        parameters: [String: any Sendable]?,
        headers: [String: String] = [:],
        requiresAuthentication: Bool,
        apiConfiguration: any MobilityAPIConfiguring
    ) {
        self.method = method
        self.URLString = URLString
        self.parameters = parameters
        self.headers = headers
        self.requiresAuthentication = requiresAuthentication
        self.apiConfiguration = apiConfiguration

        addHeaders(apiConfiguration.customHeaders)
        addCredential()
    }

    open func addHeaders(_ aHeaders: [String: String]) {
        for (header, value) in aHeaders {
            headers[header] = value
        }
    }

    @discardableResult
    open func execute(completion: @Sendable @escaping (_ result: Swift.Result<Response<T>, ErrorResponse>) -> Void) -> RequestTask {
        return requestTask
    }

    #if compiler(>=6.2)
    @concurrent
    @discardableResult
    open func execute() async throws(ErrorResponse) -> Response<T> {
        try await _execute()
    }
    #else
    @discardableResult
    open func execute() async throws(ErrorResponse) -> Response<T> {
        try await _execute()
    }
    #endif

    @discardableResult
    private func _execute() async throws(ErrorResponse) -> Response<T> {
        do {
            let requestTask = self.requestTask
            return try await withTaskCancellationHandler {
                try Task.checkCancellation()
                return try await withCheckedThrowingContinuation { continuation in
                    guard !Task.isCancelled else {
                        continuation.resume(throwing: CancellationError())
                        return
                    }

                    self.execute { result in
                        switch result {
                        case let .success(response):
                            continuation.resume(returning: response)
                        case let .failure(error):
                            continuation.resume(throwing: error)
                        }
                    }
                }
            } onCancel: {
                requestTask.cancel()
            }
        } catch {
            if let errorResponse = error as? ErrorResponse {
                throw errorResponse
            } else {
                throw ErrorResponse.error(-3, nil, nil, error)
            }
        }
    }

    public func addHeader(name: String, value: String) -> Self {
        if !value.isEmpty {
            headers[name] = value
        }
        return self
    }

    open func addCredential() {
        credential = apiConfiguration.credential
    }
}

public protocol RequestBuilderFactory: Sendable {
    func getNonDecodableBuilder<T>() -> RequestBuilder<T>.Type
    func getBuilder<T: Decodable>() -> RequestBuilder<T>.Type
}
