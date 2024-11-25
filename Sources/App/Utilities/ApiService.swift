//
//  ApiService.swift
//  backEnd_Macro
//
//  Created by Gustavo Horestee Santos Barros on 08/10/24.
//

import Fluent
import Vapor

protocol ApiService {
//    func makeURl(from orders: [Order]) async throws -> String
//    func requestTokem<T: Codable>(req: Request) async throws -> T
//    func requestData<T: Codable>(req: Request, urlString: String, modelType: T.Type, body: Data?, orderRequest: OrderRequest?) async throws -> T
//    func checkRespons(_ response: HTTPStatus) async throws
//    func verifyCode(code: String, req: Request) async throws
}

extension ApiService {
    func checkRespons(_ response: HTTPStatus) throws {
        guard (200..<300).contains(response.code) else {
            throw Api.OrderError.invalidCode
        }
    }
}
