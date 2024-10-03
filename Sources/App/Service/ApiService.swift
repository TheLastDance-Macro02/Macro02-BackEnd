//
//  ApiService.swift
//  backEnd_Macro
//
//  Created by Gustavo Horestee Santos Barros on 22/09/24.
//

import Foundation
import Vapor


class ApiService: @unchecked Sendable {
    /// Singleton instance
    static let shared: ApiService = ApiService()
    
    private let urlSession: URLSession = .shared
    
    private init() { }
    
    public func fetchData<T: Codable>(url: URL, object: Data? = nil, httpMethod: HTTPMethod, model: T.Type) async throws -> T {
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = httpMethod.rawValue
        urlRequest.httpBody = object.map(\.self)
        urlRequest.setValue(Api.MIME.jsonAp.rawValue, forHTTPHeaderField: Api.MIME.jsonAp.rawValue)
    
        let (data, response) = try await urlSession.data(for: urlRequest)
        try checkResponse(response)
        return try JSONDecoder().decode(T.self, from: data)
    }
    
    
    
    /// Verifica a resposta da chamada à API.
    private func checkResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }
    
}
