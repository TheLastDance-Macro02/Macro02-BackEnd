//
//  OrderController.swift
//  backEnd_Macro
//
//  Created by Gustavo Horestee Santos Barros on 24/09/24.
//

import Vapor
import Foundation

final class OrderController: RouteCollection, @unchecked Sendable{
    func boot(routes: any Vapor.RoutesBuilder) throws{
        let ordersRouter = routes.grouped("orders")
        
        ordersRouter.get(use: self.index)
        ordersRouter.post(use: self.create)
    }
    
    @Sendable
    func index(req: Request) async throws -> [OrderDTO]{
        do{
            return try await Order.query(on: req.db).all().map { $0.toDTO() }
        }
        catch {
            print("Erro ao requisitar todos as orders: \(String(reflecting: error))")
            throw error
        }
    }
    
    @Sendable
    func create(req: Request) async throws -> OrderDTO {
        do {
            let order = try req.content.decode(OrderDTO.self).toModel()
            try await order.save(on: req.db)
        
            return order.toDTO()
        } catch {
            print("Erro ao salvar o pedido: \(String(reflecting: error))")
            throw error
        }
    }
}


