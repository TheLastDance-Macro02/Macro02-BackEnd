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
    var amountVotes: Int
    var ratingHistory: [Double]
    var rating: Double?
    
    public func toModel() -> Carrier {
        return Carrier(id: id, deliveryName: deliveryName, amountVotes: amountVotes, ratingHistory: ratingHistory, rating: rating ?? 0.0)
    }
}
