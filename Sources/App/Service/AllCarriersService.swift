//
//  AllCarriersService.swift
//  backEnd_Macro
//
//  Created by Gustavo Horestee Santos Barros on 17/11/24.
//

import Vapor
import Fluent

//Endpoint
///"https://cheap-tracking-status.p.rapidapi.com/TrackingGetAllCouriers" -> Requisitar todas as transportadoras
///

class AllCarriersService: ApiService{
    private let url: String = "https://cheap-tracking-status.p.rapidapi.com/TrackingGetTrackingDetails"
    private let keys: [String] = [
        "2b08a63870mshf4a41ad4031d7ebp1af896jsn7eb79269a827", // --> Gabriel
        "5a239084cbmsh20dc139e3c2210dp103a1cjsn7f39a0c21a42", // --> Gustavo
        "67f818627amsh861c922f5eb8fc8p1441e4jsn2bf97136c0fd", // --> Gustavo 2
        "052468e765mshcd912f679bc3016p124342jsnc34f0796023f", // --> Gabriel 2
        "644de103a8msh03991c0f7d67656p1ff061jsn7c8ec44d662b", // --> Guilherme
        "aa2d71b9ddmshf2b5d76fac4b110p1cbaa3jsn3d28d5c94038", // --> Vitor
        "af52c79818msh191e934053c02b3p1706e6jsna2ef56598bf9", // --> Chis
        "9680d483c6msh0ed1ae9d9e639a2p1f1fd3jsnbc7c1c19e29c", // --> Chis 2
        "e6c912185fmshc13bdc7145826e2p108fe3jsncdd210f1b302", // --> Guilherme 2
    ]
    
    func requestData<T: Codable>(req: Request/*, urlString: String*/, body: Data? = nil, modelType: T.Type) async throws -> T {
        var index: Int = 0
        var responseClient: ClientResponse?
        
        while index < keys.count {
            let response = try await req.client.post("\(url)"){ req in
                req.headers.add(name: "x-rapidapi-key", value: "\(keys[index])")
                req.headers.add(name: "x-rapidapi-host", value: "cheap-tracking-status.p.rapidapi.com")
                req.headers.add(name: "Accept", value: "application/json")
                req.headers.add(name: "Content-Type", value: "application/json")
                req.body = .init(data: body ?? Data())
            }
            if response.status.code == 429{
                print("[\(response.status.code)] - Too many requests. \(keys[index]) Waiting 1 second...")
                index += 1
                try await Task.sleep(nanoseconds: 1_000_000_000)
                continue
            }
            try self.checkRespons(response.status)
            responseClient = response
            break
        }
        guard let validResponse = responseClient else {
            throw Abort(.tooManyRequests, reason: "Todas as tentativas falharam com o erro 429.")
        }
        return try validResponse.content.decode(T.self)
    }
    
    func requestAllCarriers<T: Codable>(req: Request/*, urlString: String*/, modelType: T.Type) async throws -> T {
        let response = try await req.client.get("https://cheap-tracking-status.p.rapidapi.com/TrackingGetAllCouriers"){ req in
            req.headers.add(name: "x-rapidapi-key", value: "2b08a63870mshf4a41ad4031d7ebp1af896jsn7eb79269a827")
            req.headers.add(name: "x-rapidapi-host", value: "cheap-tracking-status.p.rapidapi.com")
            req.headers.add(name: "Accept", value: "application/json")
        }
        try self.checkRespons(response.status)
        print("AQUI: \(try response.content.decode(T.self))")
        return try response.content.decode(T.self)
    }
    
    func verifyCode(requestOrder: OrderRequest, req: Request) async throws {
        ///Verifica se o código do produto é válido e se já existe no banco de dados.
        let user = try req.auth.require(User.self)
        let userID = try user.requireID()

        let exists = try await Product.query(on: req.db)
            .join(Order.self, on: \Product.$order.$id == \Order.$id)
            .filter(Order.self, \Order.$user.$id == userID)
            .filter(\.$code == requestOrder.code)
            .first() != nil
        
        if exists {
            throw Api.OrderError.codeExistsInDatabase
        }
    }
    
    public func verifyAllStatus(req: Request, modelService: ModelService, userID: UUID) async throws {
        let orders = try await modelService.loadRelationshipValues(req: req)
            .filter(\Order.$user.$id == userID)
            .all()
        
        guard !orders.isEmpty else { throw Api.OrderError.notExistCodes }
        
        let allOrders = orders.compactMap { order in
            order.products.contains(where: { $0.deliveryCompany != "Correios" }) ? order : nil
        }
        
        guard !allOrders.isEmpty else { return }
        
        for order in allOrders {
            do {
                // Apenas tenta processar cada ordem uma vez
                guard let code = order.products.first?.code, let carrierName = order.products.first?.deliveryCompany else { continue }
                let body = BodyHandler(trackingCode: code, courierCode: carrierName)
                let bodyEncoded = try JSONEncoder().encode(body)
                
                // Apenas faz uma requisição por ordem, alternando as chaves se necessário
                var response: AllCarriers.Welcome?
                for key in keys {
                    do {
                        response = try await self.requestDataWithKey(req: req, key: key, body: bodyEncoded, modelType: AllCarriers.Welcome.self)
                        break
                    } catch let error as Abort where error.status == .tooManyRequests {
                        continue
                    }
                }
                
                guard let validResponse = response else {
                    throw Abort(.tooManyRequests, reason: "Todas as tentativas falharam com erro 429.")
                }
                
                try await modelService.updateOrdersStatusAllCarriers(req: req, status: validResponse, userUUID: userID)
            } catch {
                req.logger.error("Erro ao processar ordem \(order.id ?? UUID()): \(error.localizedDescription)")
            }
        }
    }

    private func requestDataWithKey<T: Codable>(req: Request, key: String, body: Data, modelType: T.Type) async throws -> T {
        let response = try await req.client.post("\(url)") { req in
            req.headers.add(name: "x-rapidapi-key", value: key)
            req.headers.add(name: "x-rapidapi-host", value: "cheap-tracking-status.p.rapidapi.com")
            req.headers.add(name: "Accept", value: "application/json")
            req.headers.add(name: "Content-Type", value: "application/json")
            req.body = .init(data: body)
        }
        if response.status.code == 429 {
            throw Abort(.tooManyRequests)
        }
        try self.checkRespons(response.status)
        return try response.content.decode(T.self)
    }
}


struct BodyHandler: Codable {
    let trackingCode, courierCode: String
    let filterOneCourier: Bool = false

    enum CodingKeys: String, CodingKey {
        case trackingCode = "TrackingCode"
        case courierCode = "CourierCode"
        case filterOneCourier = "FilterOneCourier"
    }
}
