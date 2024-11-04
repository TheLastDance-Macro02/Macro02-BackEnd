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
    
    @Parent(key: "user_id")
    var user: User
   
    @Timestamp(key: "created_at", on: .create)
    var orderCreatedDate: Date?
    
    @Timestamp(key: "finished_at", on: .none)
    var orderFinishedDate: Date?
    
    init() {}
    
    /// Criar instância inicial
    init(id: UUID? = nil, isFavorite: Bool = false, isFinished: Bool = false, orderFinishedDate: Date? = nil, orderID: Order.IDValue) {
        self.id = id
        self.isFavorite = isFavorite
        self.isFinished = isFinished
        self.orderFinishedDate = orderFinishedDate
        self.$user.id = orderID
    }
}

extension Order{
    public func toDTO() -> OrderDTO {
        .init(
            id: id,
            isFavorite: isFavorite,
            isFinished: isFinished,
            orderCreatedAt: orderCreatedDate,
            orderFinishedAt: orderFinishedDate,
            products: products.map { $0.toDTO() }
        )
    }
}
