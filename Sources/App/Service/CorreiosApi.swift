//
//  CorreiosApi.swift
//  backEnd_Macro
//
//  Created by Gustavo Horestee Santos Barros on 30/09/24.
//

import Foundation
import Vapor


class CorreiosAPI: @unchecked Sendable {
    static let shared: CorreiosAPI = CorreiosAPI()
    
    private let apiService: ApiService = ApiService.shared
    
    private init() {}
    
    
    public func fetchData(code: String) async throws -> CorreiosModel {
        guard let url = URL(string: "urlHere\(code)") else {return CorreiosModel(text: "error")}
        
        do{
            let response = try await apiService.fetchData(url: url, object: Data(), httpMethod: .POST, model: CorreiosModel.self)
            return response
        }catch let error{
            print("ERROR in fetchData: \(error.localizedDescription)")
            throw error
        }
    }
        
    
    
    
//    func authenticateWithCorreios() {
//        guard let url = URL(string: "https://api.correios.com.br/token/v1/autentica") else { return }
//        
//        let loginData = ["username": "seu_usuario", "password": "sua_senha"]
//        
//        guard let requestBody = try? JSONSerialization.data(withJSONObject: loginData, options: []) else { return }
//        
//        ApiService.shared.fetchData(url: url, requestBody: requestBody, HTTPMethod: .post) { (result: Result<AuthResponse, Error>) in
//            switch result {
//            case .success(let authResponse):
//                print("Token recebido: \(authResponse.token)")
//                print("Expiração do token: \(authResponse.expiration)")
//            case .failure(let error):
//                print("Erro na autenticação: \(error)")
//            }
//        }
//    }
}
