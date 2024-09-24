//
//  Enuns.swift
//  backEnd_Macro
//
//  Created by Gustavo Horestee Santos Barros on 23/09/24.
//

import Foundation

struct Delivery {
    enum Company: String, CaseIterable, Codable {
        case correios
        case aliexpress
        case shopee
        case mercadoLivre
        case ups
    }
    
    enum Status: String, CaseIterable, Codable {
        case pending
        case inTransit
        case outForDelivery
        case delivered
        case failed
        case returned
        case canceled
    }
    
    enum IconProduct: String, CaseIterable, Codable {
        case phone
        case shoes
        case ball
        case house
        case book
        case tools
        case package
    }
}
