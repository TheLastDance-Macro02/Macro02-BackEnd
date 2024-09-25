//
//  ApiService.swift
//  backEnd_Macro
//
//  Created by Gustavo Horestee Santos Barros on 22/09/24.
//

import Foundation
#if canImport(Combine)
import Combine
#endif
import Vapor


class ApiService: @unchecked Sendable {
    /// Singleton instance
    static let shared: ApiService = ApiService()
    
    private let urlSession: URLSession = .shared
    
    private init() { }
    
    public func fetchData<T: Codable>(url: URL, object: Data? = nil, httpMethod: Api.HttpMethods) throws -> AnyPublisher<T, Error> {
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = httpMethod.rawValue
        urlRequest.httpBody = object
        urlRequest.setValue(Api.MIME.jsonAp.rawValue, forHTTPHeaderField: Api.MIME.jsonType.rawValue)
        
        return urlSession.dataTaskPublisher(for: urlRequest)
            .tryMap { [weak self] output in
                try self?.checkResponse(output.response)
                return output.data
            }
            .decode(type: T.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    /// Verifica a resposta da chamada à API.
    private func checkResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }
}
