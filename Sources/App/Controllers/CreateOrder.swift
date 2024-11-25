//
//  CreatOrderController.swift
//  backEnd_Macro
//
//  Created by Gustavo Horestee Santos Barros on 26/09/24.
//

import Vapor
import Fluent

struct CreateOrder: @unchecked Sendable {
//    func boot(routes: RoutesBuilder) throws {
//        let orders = routes.grouped("orders")
//        orders.get(use: getAllOrders)
//        orders.post(use: createOrder)
//        orders.get("status", use: verifyStatusOrders)
//        orders.delete("deleteAllOrders", use: deleteAllOrders)
//        orders.delete("deleteOrder", ":id", use: deleteEspecifiqueOrder)
//        orders.put("updateOrder", ":id", use: updateEspecifiqueOrder)
//
//        // Rotas temporárias para gerenciar tokens e notificações de usuários
//        let users = routes.grouped("users")
//        users.post("device", "token", use: addTokenDevice)
//        users.put("allowNotification", use: sendNotification)
//        users.delete("deleteAllUsers", use: deleteAllUsers)
//    }
    
    private let correiosService: CorreiosService
    private let modelService: ModelService
    private let allCarriers: AllCarriersService
    
    init(correiosService: CorreiosService, modelService: ModelService, allCarriers: AllCarriersService = AllCarriersService()){
        self.correiosService = correiosService
        self.modelService = modelService
        self.allCarriers = allCarriers
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
    func getAllCarriers(req: Request) async throws -> [AllCarriersDTO]{
        let carriers = try await ListCarrier.query(on: req.db).all()
            .map { $0.toDTO() }
        
        return carriers
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
        let newOrderRequest = try req.content.decode(OrderRequest.self)
        try await verifyCodeInAllCarriers(codeAndName: newOrderRequest, req: req)
        
        let newOrder = try await creatNewOrder(codeAndName: newOrderRequest, req)
        try await requestDataInCarrier(req, newOrderRequest)
        
        return try await Order.query(on: req.db)
            .filter(\.$id == newOrder.id!)
            .with(\.$products) { product in
                product.with(\.$statusHistory)
            }
            .first()!
            .toDTO()
    }
    
    private func requestDataInCarrier(_ req: Request, _ orderRequest: OrderRequest) async throws {
        let carrier = Api.Carriers.from(string: orderRequest.carrier)
        switch carrier {
        case .Correios:
            let responseCorreios = try await correiosService.requestData(req: req, urlString: "https://api.correios.com.br/srorastro/v1/objetos/\(orderRequest.code)?resultado=T", modelType: Correios.Welcome.self)
            try await modelService.updateOrdersStatusCorreios(req: req, status: responseCorreios)
        default:
            let body = BodyHandler(trackingCode: orderRequest.code, courierCode: orderRequest.carrier)
            let bodyEncodede = try JSONEncoder().encode(body)
            let response = try await self.allCarriers.requestData(req: req, body: bodyEncodede, modelType: AllCarriers.Welcome.self)
            try await modelService.updateOrdersStatusAllCarriers(req: req, status: response)
        }
    }
    
    
    private func creatNewOrder(codeAndName: OrderRequest, _ req: Request) async throws -> Order {
        let newOrder = try await modelService.saveOrder(req: req)
        try await modelService.saveProducts(orderID: newOrder.id!, req: req, codeAndName: codeAndName)
        return newOrder
    }
    
    private func verifyCodeInAllCarriers(codeAndName: OrderRequest, req: Request) async throws {
        let carrier = Api.Carriers.from(string: codeAndName.carrier)
        switch carrier {
        case .Correios:
            try await correiosService.verifyCode(code: codeAndName.code, req: req)
        default:
            try await allCarriers.verifyCode(requestOrder: codeAndName, req: req)
        }
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
        
        try await self.verifyAllStatus(req: req, modelService: modelService, userID: userID)
        
        return try await modelService.loadRelationshipValues(req: req)
            .filter(\Order.$user.$id == userID)  
            .all()
            .map { $0.toDTO() }
    }
    
    private func verifyAllStatus(req: Request, modelService: ModelService, userID: User.IDValue) async throws {
        //verificar correios primeiro
        try await self.correiosService.verifyAllStatus(req: req, modelService: modelService, userID: userID)
        //verificar 139 api depois
        try await self.allCarriers.verifyAllStatus(req: req, modelService: modelService, userID: userID)
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
