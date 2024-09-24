//
//  Carrier.swift
//  backEnd_Macro
//
//  Created by Gustavo Horestee Santos Barros on 23/09/24.
//


import Foundation

struct CarrierDTO: Codable{
    var id: UUID?
    var deliveryName: Delivery.Company
    var amountVotes: [Int]
    var rating: Double?
}
