//
//  Carrier.swift
//  backEnd_Macro
//
//  Created by Gustavo Horestee Santos Barros on 23/09/24.
//

import Vapor
import Fluent

final class Carrier: Model, @unchecked Sendable {
    static let schema: String = "carriers"
    
    @ID(key: .id)
    var id: UUID?
    
//    @Enum(key: "delivery_name")
//    var deliveryName: Delivery.Company
    
    @Field(key: "amount_votes")
    var amountVotes: Int
    
    @Field(key: "rating_history")
    var ratingHistory: [Double]
    
    @OptionalField(key: "rating")
    var rating: Double?
    
    init() {}
    
    init(id: UUID? = nil/*, deliveryName: Delivery.Company*/, amountVotes: Int = 0, ratingHistory: [Double], rating: Double? = nil) {
        self.id = id
//        self.deliveryName = deliveryName
        self.amountVotes = amountVotes
        self.ratingHistory = ratingHistory
        self.rating = rating
    }
    
    public func toDTO() -> CarrierDTO {
        .init(id: id/*, deliveryName: deliveryName*/, amountVotes: amountVotes, ratingHistory: ratingHistory, rating: rating)
    }
}
