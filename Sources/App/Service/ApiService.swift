//
//  ApiService.swift
//  backEnd_Macro
//
//  Created by Gustavo Horestee Santos Barros on 22/09/24.
//

import Foundation
//import Combine
import Vapor

class ApiService: @unchecked Sendable {
    /// Singleton instance
    static let shared = ApiService()
    
    private let urlSession: URLSession = .shared
    
    private init() { }
    
    public func fetchData<T: Decodable>(url: URL, object: Data? = nil, httpMethod: HTTPMethod, completion: @escaping (Result<T, URLError>) -> Void) {
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = httpMethod.rawValue
        urlRequest.httpBody = object.map(\.self)
        urlRequest.setValue(MIME.jsonAp.rawValue, forHTTPHeaderField: MIME.jsonAp.rawValue)
        
        let task = urlSession.dataTask(with: urlRequest) { [weak self] data, response, error in
            
            if let error = error {
                completion(.failure(error as! URLError))
                return
            }
            
            do {
                try self?.checkResponse(response!)
                
                guard let data else {
                    completion(.failure(URLError(.badServerResponse)))
                    return
                }
                
                let decodedObject = try JSONDecoder().decode(T.self, from: data)
                DispatchQueue.main.async {
                    completion(.success(decodedObject))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error as! URLError))
                }
            }
        }
        task.resume()
        
        
    }
    
    
    
    /// Verifica a resposta da chamada à API.
    private func checkResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }
}
