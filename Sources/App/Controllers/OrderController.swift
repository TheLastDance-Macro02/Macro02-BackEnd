//
//  OrderController.swift
//  backEnd_Macro
//
//  Created by Gustavo Horestee Santos Barros on 24/09/24.
//

import Vapor
import Foundation
import Fluent

final class OrderController: RouteCollection, @unchecked Sendable{
    func boot(routes: any Vapor.RoutesBuilder) throws{
        let ordersRouter = routes.grouped("orders")
        
        ordersRouter.get(use: self.index)
        ordersRouter.post(use: self.createOrder)
    }
    
    @Sendable
    func index(req: Request) async throws -> [OrderDTO]{
        do{
            let res = try await Order.query(on: req.db)
                .with(\.$products) { product in
                    product.with(\.$statusHistory)
                }
                .all()
            
            return res.map { $0.toDTO() }
        }
        catch {
            print("Erro ao requisitar todos as orders: \(String(reflecting: error))")
            throw error
        }
    }
    
    
    @Sendable
    func createOrder(req: Request) async throws -> OrderDTO {
            // Decodifica o JSON para o DTO da Order
            let orderDTO = try req.content.decode(OrderDTO.self)
            
            // Cria a instância da Order com base no DTO
            let newOrder = Order(
                isFavorite: orderDTO.isFavorite,
                isFinished: orderDTO.isFinished,
                orderFinishedDate: orderDTO.orderFinishedAt
            )
            
            // Salva a nova ordem no banco de dados
            try await newOrder.save(on: req.db)
            
            // Para cada produto no DTO, criamos e salvamos os produtos relacionados
            for productDTO in orderDTO.products {
                let newProduct = Product(
                    name: productDTO.name,
                    code: productDTO.code,
                    isFinished: productDTO.isFinished,
                    orderID: newOrder.id!,
                    deliveryStatus: productDTO.deliveryStatus,
                    deliveryCompany: productDTO.deliveryCompany
                )
                
                // Salva o produto no banco de dados
                try await newProduct.save(on: req.db)
                
                // Para cada status do produto, criamos e salvamos os históricos
                for statusHistoryDTO in productDTO.statusHistory {
                    let statusHistory = StatusHistory(
                        history: statusHistoryDTO.history,
                        historyDate: statusHistoryDTO.historyDate,
                        productID: newProduct.id!
                    )
                    
                    // Salva o status history no banco de dados
                    try await statusHistory.save(on: req.db)
                }
            }
        
        let res = try await Order.query(on: req.db)
            .filter(\Order.$id == newOrder.id!)
            .with(\.$products) { product in
                product.with(\.$statusHistory)
            } 
            .first()!
        
            return res.toDTO()
        }
}


