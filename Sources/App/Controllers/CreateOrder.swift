//
//  CreatOrderController.swift
//  backEnd_Macro
//
//  Created by Gustavo Horestee Santos Barros on 26/09/24.
//

import Vapor
import Fluent

struct CreateOrder: @unchecked Sendable {
    private let correiosService: CorreiosService
    private let modelService: ModelService
    
    init (){
        self.correiosService = CorreiosService()
        self.modelService = ModelService()
    }
    
    @Sendable
    func getAllOrders(req: Request) async throws -> [OrderDTO] {
        /// Obtém todas as ordens do usuário autenticado, mapeando-as para DTOs.
        do {
            let user = try modelService.getAuthenticatedUserID(req)
            
            let orders = try await modelService.loadRelationshipValues(req: req)
                .filter(\Order.$user.$id == user)
                .all()
            
            return orders.map { $0.toDTO() }
            
        } catch {
            throw Abort(.internalServerError, reason: "Failed in getting all orders.")
        }
    }
    
    @Sendable
    func deleteEspecifiqueOrder(req: Request) async throws -> HTTPStatus {
        guard let id = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Order ID is missing or invalid.")
        }
        
        let userID = try modelService.getAuthenticatedUserID(req)
        
        guard let order = try await Order.query(on: req.db)
                .filter(\.$id == id)
                .filter(\.$user.$id == userID)
                .first() else {
            throw Abort(.badRequest, reason: "Order not found or doesn't belong to the user.")
        }
        
        try await order.delete(on: req.db)
        return .ok
    }
    
    
    
    @Sendable
    func updateEspecifiqueOrder(req: Request) async throws -> HTTPStatus {
        guard let id = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Order ID is missing or invalid.")
        }
        
        let userID = try modelService.getAuthenticatedUserID(req)
        
        guard let order = try await Order.query(on: req.db)
                .filter(\.$id == id)
                .filter(\.$user.$id == userID)  
                .first() else {
            throw Abort(.badRequest, reason: "Order not found or doesn't belong to the user.")
        }
        
        order.isFinished = true
        try await order.save(on: req.db)
        return .ok
    }
    
    @Sendable
    func createOrder(req: Request) async throws -> OrderDTO {
        ///Cria uma nova ordem, salva os produtos e retorna a ordem criada com os produtos e histórico.
        let codeAndName = try req.content.decode(CodeAndName.self)
        try await verifyCodeInAllCarriers(codeAndName: codeAndName, req: req)
        let newOrder = try await modelService.saveOrder(req: req)
        try await modelService.saveProducts(orderID: newOrder.id!, req: req, codeAndName: codeAndName)
        
        let responseCorreios = try await correiosService.requestData(req: req, urlString: "https://api.correios.com.br/srorastro/v1/objetos/\(codeAndName.code)?resultado=T", modelType: Correios.Welcome.self)
        try await modelService.updateOrdersStatusCorreios(req: req, status: responseCorreios)
        
        return try await Order.query(on: req.db)
            .filter(\.$id == newOrder.id!)
            .with(\.$products) { product in
                product.with(\.$statusHistory)
            }
            .first()!
            .toDTO()
    }
    
    
    
    private func verifyCodeInAllCarriers(codeAndName: CodeAndName, req: Request) async throws {
        try await correiosService.verifyCode(code: codeAndName.code, req: req)
//        let carrier = Api.Carriers.from(string: codeAndName.carrier)
//        switch carrier {
//        case .Correios:
//            
//        case .Fedex:
//            print("Chamando Fedex")
//        case .Aliexpress:
//            print("Chamando Aliexpress")
//        case .Amazon:
//            print("Chamando Amazon")
//        case .DHL:
//            print("Chamando DHL")
//        case .MercadoLivre:
//            print("Chamando MercadoLivre")
//        case .UPS:
//            print("Chamando UPS")
//        case nil:
//            print("Deu nill")
//        }
    }
    
    @Sendable
    func deleteAllOrders(req: Request) async throws -> HTTPStatus {
        ///Exclui todas as ordens no banco de dados.
        try await Order.query(on: req.db).delete()
        return .ok
    }
    
    @Sendable
    func verifyStatusOrders(req: Request) async throws -> [OrderDTO] {
        let userID = try modelService.getAuthenticatedUserID(req)
        
        try await self.correiosService.verifyAllStatus(req: req, modelService: modelService, userID: userID)
//        let orders = try await modelService.loadRelationshipValues(req: req)
//            .filter(\Order.$user.$id == userID)
//            .all()
//        
//        guard !orders.isEmpty else { throw Api.OrderError.notExistCodes }
//        
//        let urlString = try await correiosService.makeURl(from: orders)
//        if urlString.contains("ERROR") {
//            return orders.map { $0.toDTO() }
//        }
//        
//        let responseCorreios = try await correiosService.requestData(req: req, urlString: urlString, modelType: Correios.Welcome.self)
//        try await modelService.updateOrdersStatusCorreios(req: req, status: responseCorreios)
        
        return try await modelService.loadRelationshipValues(req: req)
            .filter(\Order.$user.$id == userID)  
            .all()
            .map { $0.toDTO() }
    }
    
    
    //Isso nao deve ficar aqui kkkkkkkk, vai ficar pq ja to no modo se foda.
    @Sendable
    func addTokenDevice(req: Request) async throws -> HTTPStatus{
        let user = try req.auth.require(User.self)
        let deviceToken = try req.content.decode(DeviceToken.self)
        
        user.deviceToken = deviceToken.deviceToken
        
        do{
            try await user.save(on: req.db)
        }catch{
            return .badRequest
        }
        
        return .ok
    }
    
    @Sendable
    func sendNotification(req: Request) async throws -> HTTPStatus{
        let user = try req.auth.require(User.self)
       
        if user.sendNotification == nil{
            user.sendNotification = true
        }
        
//        user.sendNotification = user.t
        
        do{
            try await user.save(on: req.db)
        }catch{
            return .badRequest
        }
        
        return .ok
    }
    
    @Sendable
    func deleteAllUsers(req: Request) async throws -> HTTPStatus{
        try await User.query(on: req.db).delete()
        return .ok
    }
}

struct DeviceToken: Content{
    let deviceToken: String
}
