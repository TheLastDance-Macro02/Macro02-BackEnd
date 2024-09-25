//
//  OrderDTO.swift
//  backEnd_Macro
//
//  Created by Gustavo Horestee Santos Barros on 23/09/24.
//

import Foundation
import Vapor

struct OrderDTO: Content {
    var id: UUID?
    var is_favorite: Bool
    var is_finished: Bool
    var orderCreatedAt: Date?
    var orderFinishedAt: Date?
    var products: [ProductDTO]
    
    public func toModel() -> Order {
        let model: Order = Order()
        
        model.id = id
        model.isFavorite = is_favorite
        model.isFinished = is_finished
        model.orderCreatedDate = orderCreatedAt
        model.orderFinishedDate = orderFinishedAt
        model.products = products.map { $0.toModel() }
        
        return model
    }
    
//    enum CodingKeys: String, CodingKey {
//       case id
//       case isFavorite = "is_favorite"
//       case isFinished = "is_finished"
//       case orderCreatedAt = "orderCreatedDate"
//       case orderFinishedAt = "orderFinishedDate"
//       case products
//   }
}
