//
//  Extensions.swift
//  backEnd_Macro
//
//  Created by Gustavo Horestee Santos Barros on 22/09/24.
//

import Fluent
import Foundation




struct EnumHelper {
    static func createDeliveryStatusEnum(on database: Database) async throws -> DatabaseSchema.DataType {
        let value = try await database.enum("delivery_status")
            .case(Delivery.Status.pending.rawValue)          // "pending"
            .case(Delivery.Status.inTransit.rawValue)        // "in_transit"
            .case(Delivery.Status.outForDelivery.rawValue)   // "out_for_delivery"
            .case(Delivery.Status.delivered.rawValue)        // "delivered"
            .case(Delivery.Status.failed.rawValue)           // "failed"
            .case(Delivery.Status.returned.rawValue)         // "returned"
            .case(Delivery.Status.canceled.rawValue)         // "canceled"
            .create()
        
        return value
    }
    
    static func createCompanyEnum(on database: Database) async throws -> DatabaseSchema.DataType {
        let value = try await database.enum("delivery_company")
            .case(Delivery.Company.correios.rawValue)        // "correios"
            .case(Delivery.Company.aliexpress.rawValue)      // "aliexpress"
            .case(Delivery.Company.shopee.rawValue)          // "shopee"
            .case(Delivery.Company.mercadoLivre.rawValue)    // "mercado_livre"
            .case(Delivery.Company.ups.rawValue)             // "ups"
            .create()
        
        return value
    }
}

