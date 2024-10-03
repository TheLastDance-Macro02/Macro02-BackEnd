//
//  CreatOrderController.swift
//  backEnd_Macro
//
//  Created by Gustavo Horestee Santos Barros on 26/09/24.
//

import Vapor
import Fluent



struct CreateOrder {
    private let apiService: ApiService = ApiService.shared
    ///fazer rota /auth/callback do mercadolivre autenticar
    
    @Sendable
    func getAllOrders(req: Request) async throws -> [OrderDTO] {
        /// Obtém todas as ordens, mapeando-as para DTOs.
        do {
            let res = try await loadRelationshipValues(req: req).all().map { $0.toDTO() }
            return res
        } catch {
            print("ERROR - getAllOrders: \(String(reflecting: error))")
            throw error
        }
    }
    
    @Sendable
    func getAllFinishesOrders(req: Request) async throws -> [OrderDTO] {
        // Obtém todas as ordens marcadas como favoritas, incluindo os produtos e o histórico de status.
        do {
            return try await Order.query(on: req.db)
                .filter(\.$isFinished == true)
                .with(\.$products) { product in
                    product.with(\.$statusHistory)
                }
                .all()
                .map { $0.toDTO() }
            
        } catch {
            print("ERROR - getAllFinishesOrders: \(String(reflecting: error))")
            throw error
        }
    }
    
    @Sendable
    func getSumaryOrders(req: Request) async throws -> [SumaryOrderDTO] {
        do {
            let orders = try await loadRelationshipValues(req: req).all()
            let sumaryOrder = orders.map {order in
                let sumaryProducts = order.products.map{ product in
                    SumaryProductDTO(
                        id: product.id!,
                        name: product.name,
                        code: product.code,
                        idOrder: order.id!,
                        status: product.deliveryStatus
                    )
                }
                return SumaryOrderDTO(id: order.id!, sumaryProducts: sumaryProducts)
            }
            
            return sumaryOrder
        }catch{
            print("ERROR in getSumaryOrders: \(error.localizedDescription)")
            throw error
        }
    }
    
    @Sendable
    func getSumaryOrdersFinished(req: Request) async throws -> [SumaryOrderDTO] {
        do {
            let orders = try await loadRelationshipValues(req: req).filter(\Order.$isFinished == true).all()
            let sumaryOrder = orders.map {order in
                let sumaryProducts = order.products.map{ product in
                    SumaryProductDTO(
                        id: product.id!,
                        name: product.name,
                        code: product.code,
                        idOrder: order.id!,
                        status: product.deliveryStatus
                    )
                }
                return SumaryOrderDTO(id: order.id!, sumaryProducts: sumaryProducts)
            }
            return sumaryOrder
        }catch{
            print("ERROR in getSumaryOrders: \(error.localizedDescription)")
            throw error
        }
    }
    
    @Sendable
    func getEspecificOrder(req: Request) async throws -> OrderDTO {
        do{
            guard let order = try await Order.find(req.parameters.get("id"), on: req.db) else {
                throw Abort(.notFound)
            }
            let loadRelationships = try await Order.query(on: req.db)
                .filter(\.$id == order.id!)
                .with(\.$products) { product in
                    product.with(\.$statusHistory)
                }
                .first()!
            
            return loadRelationships.toDTO()
        }catch{
            print("ERROR in getEspecificOrder: \(error.localizedDescription)")
            throw error
        }
    }
    
    @Sendable
    func createOrder(req: Request) async throws -> OrderDTO {
        /// Cria uma nova ordem, salva os produtos e retorna a ordem criada com os produtos e histórico.
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
        /// Exclui todas as ordens no banco de dados.
        try await Order.query(on: req.db).delete()
        return .ok
    }
    
    @Sendable
    func verifyOrderStatus(req: Request) async throws -> OrderDTO {
        guard let order = try await Order.find(req.parameters.get("id"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        let loadRelationships = try await Order.query(on: req.db)
            .filter(\.$id == order.id!)
            .with(\.$products) { product in
                product.with(\.$statusHistory)
            }
            .first()!
        
        
        for product in loadRelationships.products {
            let _ = try await apiService.fetchData(url: URL(string: "bla")!, object: Data(), httpMethod: .POST, model: CorreiosModel.self)
            //logica de atualizar pedido aqui
        }
        
//        for await product in loadRelationships.products{
            //        let status = CorreiosAPI.shared.fetchData(code: order.)
//        }
//        print("Aqui - ", loadRelationships.products)
        
        
        return loadRelationships.toDTO()
        

    }
    
    
    
    //MARK: - Save data in model order
    private func saveOrder(req: Request, orderDTO: OrderDTO) async throws -> Order {
        /// Salva uma nova ordem no banco de dados.
        let newOrder = Order(
            isFavorite: orderDTO.isFavorite,
            isFinished: orderDTO.isFinished,
            orderFinishedDate: orderDTO.orderFinishedAt
        )
        try await newOrder.save(on: req.db)
        return newOrder
    }
    
    private func saveProducts(order: Order, products: [ProductDTO], req: Request) async throws {
        /// Salva os produtos associados a uma ordem no banco de dados.
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
        /// Salva o histórico de status associado a um produto no banco de dados.
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
        /// Carrega as ordens e suas relações (produtos e histórico de status).
        return Order.query(on: req.db)
            .with(\.$products) { product in
                product.with(\.$statusHistory)
            }
    }
}
