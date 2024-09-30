//
//  CreatOrderController.swift
//  backEnd_Macro
//
//  Created by Gustavo Horestee Santos Barros on 26/09/24.
//

import Vapor
import Fluent

struct CreateOrder{
//    let client = Client()
    
    @Sendable
    func getAllOrders(req: Request) async throws -> [OrderDTO] {
        do{
            
            let res = loadRelationshipValues(req: req)
            return try await res.all().map ( {$0.toDTO() } )
        }catch{
            print("ERROR - getAllOrders: \(String(reflecting: error))")
            throw error
        }
    }
    
    
    @Sendable
    func getAllFinishesOrders(req: Request) async throws -> [OrderDTO]{
        do{
            return try await Order.query(on: req.db)
                                .filter(\.$isFavorite == true)
                                .with(\.$products) { product in
                                    product.with(\.$statusHistory)
                                }
                                .all()
                                .map {$0.toDTO()}
        }catch{
            print("ERROR - getAllFinishesOrders: \(String(reflecting: error))")
            throw error
        }
    }
    
    @Sendable
    func createOrder(req: Request) async throws -> OrderDTO {
        let orderDTO = try req.content.decode(OrderDTO.self)
        let newOrder = try await saveOrder(req: req, orderDTO: orderDTO)
        try await saveProducts(order: newOrder, products: orderDTO.products, req: req)
        
        return try await Order.query(on: req.db)
            .filter(\.$id == newOrder.id!)
            .with(\.$products) { product in
                product.with(\.$statusHistory)
            }
            .first()!
            .toDTO()
    }
    
    @Sendable
    func deleteAllOrders(req: Request) async throws -> HTTPStatus {
        try await Order.query(on: req.db).delete()
        return .ok
    }
    
    private func saveOrder(req: Request, orderDTO: OrderDTO) async throws -> Order {
        let newOrder = Order(
            isFavorite: orderDTO.isFavorite,
            isFinished: orderDTO.isFinished,
            orderFinishedDate: orderDTO.orderFinishedAt
        )
        try await newOrder.save(on: req.db)
        return newOrder
    }
    
    private func saveProducts(order: Order, products: [ProductDTO], req: Request) async throws {
        for productDTO in products {
            let newProduct = Product(
                name: productDTO.name,
                code: productDTO.code,
                isFinished: productDTO.isFinished,
                orderID: order.id!,
                deliveryStatus: productDTO.deliveryStatus,
                deliveryCompany: productDTO.deliveryCompany
            )
            try await newProduct.save(on: req.db)
            try await saveStatusHistory(product: newProduct, statusHistory: productDTO.statusHistory, req: req)
        }
    }
    
    private func saveStatusHistory(product: Product, statusHistory: [StatusHistoryDTO], req: Request) async throws {
        for statusHistoryDTO in statusHistory {
            let newStatusHistory = StatusHistory(
                history: statusHistoryDTO.history,
                historyDate: statusHistoryDTO.historyDate,
                productID: product.id!
            )
            try await newStatusHistory.save(on: req.db)
        }
    }
    
    func loadRelationshipValues(req: Request) -> QueryBuilder<Order> {
       return Order.query(on: req.db)
                .with(\.$products) { product in
                    product.with(\.$statusHistory)
                }
    }
}
