//
//  StatusHistory.swift
//  backEnd_Macro
//
//  Created by Gustavo Horestee Santos Barros on 23/09/24.
//

import Vapor
import Fluent

final class StatusHistory: Model, @unchecked Sendable {
    static let schema: String = "status_history"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "history")
    var history: String
    
    @Field(key: "history_date")
    var historyDate: Date
    
    @Parent(key: "product_id")
    var product: Product
    
    init() {}
    
    init(id: UUID? = nil, history: String, historyDate: Date, productID: Product.IDValue) {
        self.id = id
        self.history = history
        self.historyDate = historyDate
        self.$product.id = productID
    }
    
    public func toDTO() -> StatusHistoryDTO {
        return .init(id: id, history: history, historyDate: historyDate, productId: self.$product.id)
    }
}
