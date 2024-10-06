//
//  Product.swift
//  backEnd_Macro
//
//  Created by Gustavo Horestee Santos Barros on 23/09/24.
//

import Vapor
import Fluent

final class Product: Model, @unchecked Sendable {
    static let schema: String = "products"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "name")
    var name: String
    
    @Field(key: "code")
    var code: String
    
    @Field(key: "is_finished")
    var isFinished: Bool
    
    @Parent(key: "order_id")
    var order: Order
    
    @OptionalField(key: "delivery_status")
    var deliveryStatus: String?
    
    @OptionalField(key: "delivery_company")
    var deliveryCompany: String?
    
    @OptionalField(key: "dt_predicted")
    var dtPredicted: Date?
    
    @Children(for: \StatusHistory.$product)
    var statusHistory: [StatusHistory]
    
    init() {}
    
    init(id: UUID? = nil, name: String, code: String, isFinished: Bool = false, orderID: Order.IDValue, deliveryStatus: String? = nil, deliveryCompany: String? = nil, dtPredicted: Date? = nil) {
        self.id = id
        self.name = name
        self.code = code
        self.isFinished = isFinished
        self.$order.id = orderID
        self.deliveryStatus = deliveryStatus
        self.deliveryCompany = deliveryCompany
        self.dtPredicted = dtPredicted
    }
}

extension Product{
    public func toDTO() -> ProductDTO {
        .init(
            id: id,
            name: name,
            code: code,
            isFinished: isFinished,
            orderID: $order.id,
            deliveryStatus: deliveryStatus,
            statusHistory: statusHistory.map { $0.toDTO() },
            deliveryCompany: deliveryCompany,
            dtPredicted: dtPredicted
        )
    }
}
