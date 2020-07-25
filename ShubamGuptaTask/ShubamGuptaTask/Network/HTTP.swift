//
//  HTTP.swift
//  Binger
//
//  Created by Appiness on 8/27/19.
//  Copyright © 2019 Appiness. All rights reserved.
//

import Foundation

// Blocks to handle http request response
typealias CompletionBlock = (_ status: HTTPStatus, _ object: AnyObject?, _ msg: String) -> Void

enum HTTPStatus: Int {
    case success = 200
    case badRequest = 400
    case unauthorized = 401
    case forbidden = 403
    case notFound = 404
    case internalError = 500
    case gatewayError = 502
    case serviceUnavailable = 503
    case urlError = 0
    case serialisationError = 1
    case deserialisationError = 2
    case unknown = 3
}
enum CustomError: String {
    case invalidUrl = "Invalid URL"
    case unableToParse = "Something went wrong"
    case requestTimeOut = "Request Timeout"
    case unauthorizedAccess = "unauthorized access"
}

enum HTTPMethod: String {
    case get    = "GET"
    case post   = "POST"
    case put    = "PUT"
    case delete = "DELETE"
}

// Protocol to handle http response
protocol HTTPDelegate: NSObjectProtocol {
    func completed(withStatus status: HTTPStatus, responseObject object: AnyObject?, andErrorMsg msg: String, urlString urlStr: String?)
}

struct ThreadSwitcher {
    let status: HTTPStatus
    let response: AnyObject?
    let message: String
    let urlString: String?
}

class HTTP: NSObject {
    fileprivate var task: URLSessionTask?
    fileprivate var completionBlock: CompletionBlock?
    fileprivate weak var delegate: HTTPDelegate?
    fileprivate var threadSwitcher: ThreadSwitcher {
        get {
            return ThreadSwitcher(status: HTTPStatus.unknown, response: nil, message: "", urlString: "")
        }
        set {
            task = nil
            DispatchQueue.main.async {
                if let completionBlock = self.completionBlock {
                    completionBlock(newValue.status, newValue.response, newValue.message)
                } else {
                    self.delegate?.completed(withStatus: newValue.status, responseObject: newValue.response, andErrorMsg: newValue.message, urlString: newValue.urlString)
                }
            }
        }
    }
    
    init(delegate: HTTPDelegate?) {
        self.delegate = delegate
    }
    init(withBlock completionBLock: @escaping CompletionBlock) {
        self.completionBlock  = completionBLock
    }
    
    func cancel() {
        guard let task = task else { return }
        task.cancel()
    }
    
    func request<T: Codable>(ofType method: HTTPMethod, responseType: T.Type,
                             endPoint enpoint: Endpoint,
                             withPararmeters parameter: [String: String] = [:],
                             andHeaders headers: [String: String] = [:],
                             shouldPassToken should: Bool = false) {
        
        guard let url = enpoint.url else {
            threadSwitcher =  ThreadSwitcher(status: .urlError, response: nil, message: CustomError.invalidUrl.rawValue, urlString: nil)
            return
        }
        print(url.absoluteString)
        var request = URLRequest(url: url)
        // Add request method.
        request.httpMethod = method.rawValue
        // Add headers.
        for header in headers {
            print("Header value ----", header.value)
            request.addValue(header.value, forHTTPHeaderField: header.key)
        }
        
        for params in parameter {
            print("Param value ---", params.value)
            request.addValue(params.value, forHTTPHeaderField: params.key)
        }
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    
        // Make request.
        sendRequest(request: request, responseType: responseType)
    }
    
    func sendRequest<T: Codable>(request: URLRequest, responseType: T.Type) {
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig)
        let methodStart = Date()
        task = session.dataTask(with: request, completionHandler: { (data, response, error) in
            var status: Int = 500
            DispatchQueue.main.async {
                let methodFinish = Date()
                let executionTime = methodFinish.timeIntervalSince(methodStart)
                print("Execution time: \(executionTime)")
            }
            if let tempResponse = response as? HTTPURLResponse {
                status = tempResponse.statusCode
                if status == 201 || status == 204 || status == 202 { status = 200 }
            }
            print("status..........: \(status)")
            if let tempError = error {
                print("Some error occurred: \(tempError.localizedDescription)")
               self.threadSwitcher = ThreadSwitcher(status: (HTTPStatus(rawValue: status) ?? .unknown), response: nil, message: tempError.localizedDescription, urlString: request.url?.absoluteString)
                return
            }
            guard let data  = data else {
                print("Request timed out.")
                self.threadSwitcher = ThreadSwitcher(status: (HTTPStatus(rawValue: status) ?? .unknown), response: nil, message: CustomError.requestTimeOut.rawValue, urlString: request.url?.absoluteString)
                return
            }
            
            do {
                let jsonDecoder = JSONDecoder()
                jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
                let result = try jsonDecoder.decode(responseType, from: data)
                self.threadSwitcher = ThreadSwitcher(status: (HTTPStatus(rawValue: status) ?? .unknown), response: result as AnyObject, message: (HTTPStatus(rawValue: status) ?? .unknown) == .success ? "success" : "failed", urlString: request.url?.absoluteString)
                return
            } catch {
                print(error)
                if let result = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) {
                    self.threadSwitcher = ThreadSwitcher(status: (HTTPStatus(rawValue: status) ?? .unknown), response: result as AnyObject, message: error.localizedDescription, urlString: request.url?.absoluteString)
                } else {
                    let result = String(data: data, encoding: .utf8)
                    print("Couldn't get JSON from data.", "Got string: ", result ?? "Nope not a String either.")
                     self.threadSwitcher = ThreadSwitcher(status: (HTTPStatus(rawValue: status) ?? .deserialisationError), response: nil, message: result ?? "unable to parse", urlString: request.url?.absoluteString)
                }
                return
            }
           
        })
        task?.resume()
    }
    
}

// JSON Stringifier.
private extension HTTP {
    func JSONStringify(withJSON value: AnyObject, prettyPrinted: Bool = false) -> Data? {
        let options = prettyPrinted ? JSONSerialization.WritingOptions.prettyPrinted : JSONSerialization.WritingOptions(rawValue: 0)
        if JSONSerialization.isValidJSONObject(value) {
            do {
                return try JSONSerialization.data(withJSONObject: value, options: options)
            } catch { print("Couldn't serialize JSON.") }
        }
        return nil
    }
}
