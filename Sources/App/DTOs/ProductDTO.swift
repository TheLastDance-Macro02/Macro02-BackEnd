//
//  ProductDTO.swift
//  backEnd_Macro
//
//  Created by Gustavo Horestee Santos Barros on 24/09/24.
//

import Foundation
import Vapor

struct ProductDTO: Content {
    var id: UUID?
    var name: String
    var code: String
    var isFinished: Bool
//    var orderID: Order.IDValue
    var deliveryStatus: String?
    var statusHistory: [StatusHistoryDTO]
    var deliveryCompany: String?
    
    public func toModel() -> Product {
        let model = Product()
        
        model.id = id
        model.name = name
        model.code = code
        model.isFinished = isFinished
//        model.$order.id = orderID
        model.deliveryStatus = deliveryStatus
        model.statusHistory = statusHistory.map { $0.toModel() }
        model.deliveryCompany = deliveryCompany
        
        return model
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case code
        case isFinished = "is_finished" // Mapeia a chave is_finished para isFinished
//        case orderID = "order_id"        // Mapeia a chave order_id para orderID
        case deliveryStatus = "delivery_status" // Mapeia a chave delivery_status
        case deliveryCompany = "delivery_company" // Mapeia a chave delivery_company
        case statusHistory // Para mapeamento automático
    }
}
