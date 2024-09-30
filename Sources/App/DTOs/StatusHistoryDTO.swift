//
//  StatusHistoryDTO.swift
//  backEnd_Macro
//
//  Created by Gustavo Horestee Santos Barros on 23/09/24.
//

import Foundation
import Vapor


struct StatusHistoryDTO: Content {
    var id: UUID?
    var history: String
    var historyDate: Date
    var productId: Product.IDValue?
    
    public func toModel() -> StatusHistory {
        let model = StatusHistory()
        
        model.id = id
        model.history = history
        model.historyDate = historyDate
        model.$product.id = productId!
        
        return model
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case history
        case historyDate = "history_date" // Mapeia a chave history_date
        case productId = "product_id"      // Mapeia a chave product_id
    }
}
