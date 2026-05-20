#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NETWORKING_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
SPEC_DIR="${SCRIPT_DIR}/Spec"
OUTPUT_ROOT="${NETWORKING_DIR}/OpenApiClientGenerated"
SHARED_DIR="${OUTPUT_ROOT}/Shared"

GENERATOR_FLAGS=(
  -g swift6
  --library=alamofire
  "--additional-properties=responseAs=AsyncAwait,removeMigrationProjectNameClass=true,readonlyProperties=true,nonPublicApi=false,useSPMFileStructure=false,hideGenerationTimestamp=true"
)

declare -a SERVICES=(
  "CityBike:${SPEC_DIR}/CityBikeAPI.yaml"
  "OpenMeteo:${SPEC_DIR}/OpenMeteoAPI.yaml"
)

echo "Generating Urban Mobility OpenAPI clients (Swift 6)…"
echo "Output: ${OUTPUT_ROOT}"
echo ""

SHARED_CREATED=false

copy_tree_swift_files() {
  local source_dir="$1"
  local dest_dir="$2"
  mkdir -p "${dest_dir}"
  find "${source_dir}" -name '*.swift' -print0 | while IFS= read -r -d '' file; do
    cp "${file}" "${dest_dir}/$(basename "${file}")"
  done
}

for service_config in "${SERVICES[@]}"; do
  IFS=':' read -r service_name spec_path <<< "${service_config}"

  if [[ ! -f "${spec_path}" ]]; then
    echo "Spec not found: ${spec_path}"
    exit 1
  fi

  echo "→ ${service_name}"

  temp_dir="${OUTPUT_ROOT}/${service_name}_Temp"
  final_dir="${OUTPUT_ROOT}/${service_name}_OpenAPI"
  rm -rf "${temp_dir}" "${final_dir}"

  openapi-generator generate \
    "${GENERATOR_FLAGS[@]}" \
    -i "${spec_path}" \
    -o "${temp_dir}" \
    "--additional-properties=projectName=${service_name},modelNamePrefix=${service_name}"

  source_root="${temp_dir}/${service_name}/Classes/OpenAPIs"
  if [[ ! -d "${source_root}" ]]; then
    echo "Unexpected generator layout under ${temp_dir}"
    find "${temp_dir}" -maxdepth 4 -type d
    exit 1
  fi

  if [[ "${SHARED_CREATED}" == false ]]; then
    echo "  • shared infrastructure"
    rm -rf "${SHARED_DIR}"
    mkdir -p "${SHARED_DIR}"
    copy_tree_swift_files "${source_root}/Infrastructure" "${SHARED_DIR}"
    SHARED_CREATED=true
  fi

  mkdir -p "${final_dir}"
  if [[ -d "${source_root}/APIs" ]]; then
    copy_tree_swift_files "${source_root}/APIs" "${final_dir}"
  fi
  if [[ -d "${source_root}/Models" ]]; then
    copy_tree_swift_files "${source_root}/Models" "${final_dir}"
  fi

  rm -rf "${temp_dir}"
  echo "  • ${final_dir}"
  echo ""
done

# Dual-service configuration (two base paths, one shared request stack).
cat > "${SHARED_DIR}/APIs.swift" << 'SWIFT'
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
SWIFT

# Alamofire builders accept any service configuration (dual base URL setup).
if [[ -f "${SHARED_DIR}/AlamofireImplementations.swift" ]]; then
  perl -0pi -e 's/apiConfiguration: CityBikeAPIConfiguration = CityBikeAPIConfiguration\.shared/apiConfiguration: any MobilityAPIConfiguring/g' "${SHARED_DIR}/AlamofireImplementations.swift"
  perl -0pi -e 's/apiConfiguration: OpenMeteoAPIConfiguration = OpenMeteoAPIConfiguration\.shared/apiConfiguration: any MobilityAPIConfiguring/g' "${SHARED_DIR}/AlamofireImplementations.swift"
fi

# Policy: no print/Logger in generated clients (re-apply after each regen).
if [[ -f "${SHARED_DIR}/JSONEncodingHelper.swift" ]]; then
  perl -0pi -e 's/print\(error\.localizedDescription\)/\/\/ encoding error ignored/g' "${SHARED_DIR}/JSONEncodingHelper.swift"
fi

# CityBikes: renting/returning are Int on some networks and Bool on others (e.g. callabike-berlin).
EXTRA_FILE="${OUTPUT_ROOT}/CityBike_OpenAPI/CityBikeStationExtra.swift"
if [[ -f "${EXTRA_FILE}" ]]; then
  if ! grep -q 'decodeFlexibleServiceFlag' "${EXTRA_FILE}"; then
    perl -0pi -e '
      s/renting = try container\.decodeIfPresent\(Int\.self, forKey: \.renting\)/renting = Self.decodeFlexibleServiceFlag(from: container, forKey: .renting)/g;
      s/returning = try container\.decodeIfPresent\(Int\.self, forKey: \.returning\)/returning = Self.decodeFlexibleServiceFlag(from: container, forKey: .returning)/g;
    ' "${EXTRA_FILE}"
    perl -0pi -e 's/(    private static func decodeFlexibleUID)/    private static func decodeFlexibleServiceFlag(\n        from container: KeyedDecodingContainer<CodingKeys>,\n        forKey key: CodingKeys\n    ) -> Int? {\n        if let int = try? container.decodeIfPresent(Int.self, forKey: key) {\n            return int\n        }\n        if let bool = try? container.decodeIfPresent(Bool.self, forKey: key) {\n            return bool ? 1 : 0\n        }\n        return nil\n    }\n\n$1/s' "${EXTRA_FILE}"
  fi
fi

echo "Done. Shared + service folders are ready under ${OUTPUT_ROOT}."
