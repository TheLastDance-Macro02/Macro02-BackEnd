//
//  Enuns.swift
//  backEnd_Macro
//
//  Created by Gustavo Horestee Santos Barros on 23/09/24.
//

import Foundation

struct Delivery {
    enum Company: String, CaseIterable, Codable {
        case correios = "correios"
        case aliexpress = "aliexpress"
        case shopee = "shopee"
        case mercadoLivre = "mercado_livre"
        case ups = "ups"
    }
    
    enum Status: String, CaseIterable, Codable {
        case pending = "pending"
        case inTransit = "in_transit"
        case outForDelivery = "out_for_delivery"
        case delivered = "delivered"
        case failed = "failed"
        case returned = "returned"
        case canceled = "canceled"
    }
}
