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
        ///Obtém todas as ordens, mapeando-as para DTOs.
        do {
            return try await modelService.loadRelationshipValues(req: req)
                .all()
                .map { $0.toDTO() }
        } catch {
            print("ERROR - getAllOrders: \(String(reflecting: error))")
            throw error
        }
    }
    
    @Sendable
    func deleteEspecifiqueOrder(req: Request) async throws -> HTTPStatus {
        guard let id = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Order ID is missing or invalid.")
        }
        guard let order = try await Order.find(id, on: req.db) else {
            throw Abort(.badRequest, reason: "Missing order ID.")
        }
        try await order.delete(on: req.db)
        return .ok
    }
    
    @Sendable
    func updateEspecifiqueOrder(req: Request) async throws -> HTTPStatus {
        guard let id = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Order ID is missing or invalid.")
        }
        guard let order = try await Order.find(id, on: req.db) else {
            throw Abort(.badRequest, reason: "Missing order ID.")
        }
        
        order.isFinished = true
        try await order.save(on: req.db)
        return .ok
    }
    
    @Sendable
    func createOrder(req: Request) async throws -> OrderDTO {
        ///Cria uma nova ordem, salva os produtos e retorna a ordem criada com os produtos e histórico.
        let codeAndName = try req.content.decode(CodeAndName.self)
        try await verifyCodeInAllCarriers(code: codeAndName.code, req: req)
        let newOrder = try await modelService.saveOrder(req: req)
        try await modelService.saveProducts(orderID: newOrder.id!, req: req, codeAndName: codeAndName)
        return try await Order.query(on: req.db)
            .filter(\.$id == newOrder.id!)
            .with(\.$products) { product in
                product.with(\.$statusHistory)
            }
            .first()!
            .toDTO()
    }
    
    private func verifyCodeInAllCarriers(code: String, req: Request) async throws {
        try await correiosService.verifyCode(code: code, req: req)
    }
    
    @Sendable
    func deleteAllOrders(req: Request) async throws -> HTTPStatus {
        ///Exclui todas as ordens no banco de dados.
        try await Order.query(on: req.db).delete()
        return .ok
    }
    
    @Sendable
    func verifyStatusOrders(req: Request) async throws -> [OrderDTO] {
        ///Verifica o status das ordens e atualiza com base nas informações dos Correios.
        let orders = try await modelService.loadRelationshipValues(req: req).all()
        guard !orders.isEmpty else { throw Api.OrderError.notExistCodes }
        print("Aqui: ", orders.first?.products.first?.code as Any)
        let urlString = try await correiosService.makeURl(from: orders)
        if urlString.contains("ERROR"){
            return try await modelService.loadRelationshipValues(req: req)
                .all()
                .map { $0.toDTO() }
        }
        let responseCorreios = try await correiosService.requestData(req: req, urlString: urlString, modelType: Correios.Welcome.self)
        try await modelService.updateOrdersStatus(req: req, status: responseCorreios)
        return try await modelService.loadRelationshipValues(req: req)
            .all()
            .map { $0.toDTO() }
    }
    
//    private func requestCodeInAllApi(req: Request, orders: [Order]) async throws -> Order{
//        
//    }
}
