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
    ]
    
    func requestData<T: Codable>(req: Request/*, urlString: String*/, body: Data? = nil, modelType: T.Type) async throws -> T {
        var index: Int = 0
        var responseClient: ClientResponse?
        
        while index < keys.count {
            let response = try await req.client.post("\(url)"){ req in
                req.headers.add(name: "x-rapidapi-key", value: keys[index])
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
    
    public func verifyAllStatus(req: Request, modelService: ModelService, userID: UUID) async throws{
        let orders = try await modelService.loadRelationshipValues(req: req)
            .filter(\Order.$user.$id == userID)
            .all()
        
        guard !orders.isEmpty else { throw Api.OrderError.notExistCodes }
        
//        print("Antes", orders.count)
        
        let allOrders = orders.compactMap { order in
            if order.products.contains(where: { $0.deliveryCompany != "Correios" }) {
                return order
            }
            return nil
        }
        
//        print("Depois", allOrders.count)
        
        guard !allOrders.isEmpty else { return }
        
        for order in allOrders {
            do{
                guard let code = order.products.first?.code, let carrierName = order.products.first?.deliveryCompany else { continue }
                let body = BodyHandler(trackingCode: code, courierCode: carrierName)
                let bodyEncodede = try JSONEncoder().encode(body)
                let response = try await self.requestData(req: req, body: bodyEncodede, modelType: AllCarriers.Welcome.self)
                try await modelService.updateOrdersStatusAllCarriers(req: req, status: response, userUUID: userID)
            }catch{
//                print("Erro ao processar ordem \(order.id ?? UUID()): \(error.localizedDescription)")
                req.logger.error("Erro ao processar ordem \(order.id ?? UUID()): \(error.localizedDescription)")
            }
        }
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
