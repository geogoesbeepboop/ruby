import Foundation
import Network
import Combine
/// Robust HTTP client with comprehensive error handling, retry logic, and network monitoring
@MainActor
final class HTTPClient: ObservableObject {
    var objectWillChange = ObservableObjectPublisher()
    
    private let session: URLSession
    private let networkMonitor: NWPathMonitor
    private let queue = DispatchQueue(label: "HTTPClient.NetworkMonitor")
    
    @Published var isNetworkAvailable = true
    
    // Configuration
    struct Configuration {
        let timeoutInterval: TimeInterval = 30.0
        let maxRetryAttempts = 3
        let retryDelay: TimeInterval = 1.0
        let enableLogging = true
    }
    
    private let config = Configuration()
    
    init() {
        // Configure URLSession with proper timeout and cache policies
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = config.timeoutInterval
        configuration.timeoutIntervalForResource = config.timeoutInterval * 2
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        configuration.urlCache = URLCache(
            memoryCapacity: 50 * 1024 * 1024, // 50MB memory
            diskCapacity: 100 * 1024 * 1024,  // 100MB disk
            diskPath: "http_cache"
        )
        
        self.session = URLSession(configuration: configuration)
        self.networkMonitor = NWPathMonitor()
        
        setupNetworkMonitoring()
    }
    
    deinit {
        networkMonitor.cancel()
        session.invalidateAndCancel()
    }
}

// MARK: - Network Monitoring
extension HTTPClient {
    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isNetworkAvailable = path.status == .satisfied
            }
        }
        networkMonitor.start(queue: queue)
    }
}

// MARK: - HTTP Methods
extension HTTPClient {
    func get<T: Codable>(
        _ type: T.Type,
        from url: URL,
        headers: [String: String]? = nil
    ) async throws -> T {
        try await performRequest(type, url: url, method: .GET, headers: headers, body: Optional<Never>.none)
    }
    
    func post<T: Codable, U: Codable>(
        _ type: T.Type,
        to url: URL,
        body: U,
        headers: [String: String]? = nil
    ) async throws -> T {
        try await performRequest(
            type,
            url: url,
            method: .POST,
            headers: headers,
            body: body
        )
    }
    
    // New flexible methods for unknown response structures
    func getRawData(
        from url: URL,
        headers: [String: String]? = nil
    ) async throws -> Data {
        try await performRawRequest(url: url, method: .GET, headers: headers, body: Optional<Never>.none)
    }
    
    func getJSON(
        from url: URL,
        headers: [String: String]? = nil
    ) async throws -> [String: Any] {
        let data = try await getRawData(from: url, headers: headers)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw HTTPError.decodingFailure(NSError(domain: "HTTPClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "Response is not a JSON object"]))
        }
        return json
    }
    
    func getFlexible<T: Codable>(
        _ type: T.Type,
        from url: URL,
        headers: [String: String]? = nil,
        fallbackHandler: ((Data) throws -> T)? = nil
    ) async throws -> T {
        let data = try await getRawData(from: url, headers: headers)
        
        // Try primary decoding first
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            if config.enableLogging {
                print("⚠️ [HTTPClient] Primary decode failed: \(error)")
            }
            
            // Try fallback handler if provided
            if let fallbackHandler = fallbackHandler {
                do {
                    return try fallbackHandler(data)
                } catch {
                    if config.enableLogging {
                        print("⚠️ [HTTPClient] Fallback decode failed: \(error)")
                    }
                }
            }
            
            // Log raw response for debugging
            if config.enableLogging {
                let responseString = String(data: data, encoding: .utf8) ?? "Unable to decode as UTF-8"
                print("🔍 [HTTPClient] Raw response: \(responseString)")
            }
            
            throw HTTPError.decodingFailure(error)
        }
    }
}

// MARK: - Core Request Logic
extension HTTPClient {
    private func performRequest<T: Codable, U: Codable>(
        _ type: T.Type,
        url: URL,
        method: HTTPMethod,
        headers: [String: String]? = nil,
        body: U? = nil
    ) async throws -> T {
        
        // Check network availability
        guard isNetworkAvailable else {
            throw HTTPError.networkUnavailable
        }
        
        // Retry logic with exponential backoff
        var lastError: Error?
        
        for attempt in 1...config.maxRetryAttempts {
            do {
                let request = try buildRequest(
                    url: url,
                    method: method,
                    headers: headers,
                    body: body
                )
                
                if config.enableLogging {
                    print("🌐 [HTTPClient] \(method.rawValue) \(url) (attempt \(attempt))")
                }
                
                let (data, response) = try await session.data(for: request)
                
                // Validate response
                try validateResponse(response, data: data)
                
                // Decode response
                let result = try JSONDecoder().decode(type, from: data)
                
                if config.enableLogging {
                    print("✅ [HTTPClient] Success: \(url)")
                }
                
                return result
                
            } catch let error as HTTPError {
                lastError = error
                
                // Don't retry for certain errors
                if !error.shouldRetry || attempt == config.maxRetryAttempts {
                    break
                }
                
                // Exponential backoff
                let delay = config.retryDelay * pow(2.0, Double(attempt - 1))
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                
            } catch {
                lastError = HTTPError.decodingFailure(error)
                break
            }
        }
        
        throw lastError ?? HTTPError.unknownError
    }
    
    private func performRawRequest<U: Codable>(
        url: URL,
        method: HTTPMethod,
        headers: [String: String]? = nil,
        body: U? = nil
    ) async throws -> Data {
        
        // Check network availability
        guard isNetworkAvailable else {
            throw HTTPError.networkUnavailable
        }
        
        // Retry logic with exponential backoff
        var lastError: Error?
        
        for attempt in 1...config.maxRetryAttempts {
            do {
                let request = try buildRequest(
                    url: url,
                    method: method,
                    headers: headers,
                    body: body
                )
                
                if config.enableLogging {
                    print("🌐 [HTTPClient] \(method.rawValue) \(url) (attempt \(attempt))")
                }
                
                let (data, response) = try await session.data(for: request)
                
                // Validate response
                try validateResponse(response, data: data)
                
                if config.enableLogging {
                    print("✅ [HTTPClient] Success: \(url)")
                }
                
                return data
                
            } catch let error as HTTPError {
                lastError = error
                
                // Don't retry for certain errors
                if !error.shouldRetry || attempt == config.maxRetryAttempts {
                    break
                }
                
                // Exponential backoff
                let delay = config.retryDelay * pow(2.0, Double(attempt - 1))
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                
            } catch {
                lastError = HTTPError.decodingFailure(error)
                break
            }
        }
        
        throw lastError ?? HTTPError.unknownError
    }
    
    private func buildRequest<U: Codable>(
        url: URL,
        method: HTTPMethod,
        headers: [String: String]?,
        body: U?
    ) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        
        // Default headers
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("iOS-LotusChatBot/1.0", forHTTPHeaderField: "User-Agent")
        
        // Custom headers
        headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Body for POST/PUT requests
        if let body = body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(body)
        }
        
        return request
    }
    
    private func validateResponse(_ response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw HTTPError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            return
        case 400...499:
            throw HTTPError.clientError(httpResponse.statusCode)
        case 500...599:
            throw HTTPError.serverError(httpResponse.statusCode)
        default:
            throw HTTPError.unexpectedStatusCode(httpResponse.statusCode)
        }
    }
}

// MARK: - Supporting Types
extension HTTPClient {
    enum HTTPMethod: String {
        case GET = "GET"
        case POST = "POST"
        case PUT = "PUT"
        case DELETE = "DELETE"
        case PATCH = "PATCH"
    }
}

enum HTTPError: LocalizedError, Equatable {
    case networkUnavailable
    case invalidURL
    case invalidResponse
    case clientError(Int)
    case serverError(Int)
    case unexpectedStatusCode(Int)
    case decodingFailure(Error)
    case timeoutError
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "Network connection unavailable"
        case .invalidURL:
            return "Invalid URL provided"
        case .invalidResponse:
            return "Invalid response received"
        case .clientError(let code):
            return "Client error: \(code)"
        case .serverError(let code):
            return "Server error: \(code)"
        case .unexpectedStatusCode(let code):
            return "Unexpected status code: \(code)"
        case .decodingFailure:
            return "Failed to decode response"
        case .timeoutError:
            return "Request timed out"
        case .unknownError:
            return "Unknown error occurred"
        }
    }
    
    var shouldRetry: Bool {
        switch self {
        case .networkUnavailable, .serverError, .timeoutError:
            return true
        case .clientError, .invalidURL, .invalidResponse, .decodingFailure, .unexpectedStatusCode, .unknownError:
            return false
        }
    }
    
    static func == (lhs: HTTPError, rhs: HTTPError) -> Bool {
        switch (lhs, rhs) {
        case (.networkUnavailable, .networkUnavailable),
             (.invalidURL, .invalidURL),
             (.invalidResponse, .invalidResponse),
             (.timeoutError, .timeoutError),
             (.unknownError, .unknownError):
            return true
        case (.clientError(let code1), .clientError(let code2)),
             (.serverError(let code1), .serverError(let code2)),
             (.unexpectedStatusCode(let code1), .unexpectedStatusCode(let code2)):
            return code1 == code2
        default:
            return false
        }
    }
}
