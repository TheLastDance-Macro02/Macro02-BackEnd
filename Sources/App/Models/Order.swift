//
//  Order.swift
//  backEnd_Macro
//
//  Created by Gustavo Horestee Santos Barros on 23/09/24.
//

import Vapor
import Fluent

final class Order: Model, @unchecked Sendable {
    static let schema: String = "orders"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "is_favorite")
    var isFavorite: Bool
    
    @Field(key: "is_finished")
    var isFinished: Bool
    
    @Children(for: \.$order)
    var products: [Product]
    
    @Timestamp(key: "created_at", on: .create)
    var orderCreatedDate: Date?
    
    @Timestamp(key: "finished_at", on: .none)
    var orderFinishedDate: Date?
    
    init() {}
    
    /// Criar instância inicial
    init(id: UUID? = nil, isFavorite: Bool = false, isFinished: Bool = false, orderFinishedDate: Date? = nil) {
        self.id = id
        self.isFavorite = isFavorite
        self.isFinished = isFinished
        self.orderFinishedDate = orderFinishedDate
    }
    
    public func toDTO() -> OrderDTO {
        .init(
            id: id,
            is_favorite: isFavorite,
            is_finished: isFinished,
            orderCreatedAt: orderCreatedDate,
            orderFinishedAt: orderFinishedDate,
            products: products.map { $0.toDTO() }
        )
    }
}
