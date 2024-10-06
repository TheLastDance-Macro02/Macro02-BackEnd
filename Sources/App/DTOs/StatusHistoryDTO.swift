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
//    var history: String?
    var dtCreated: Date?
    var productId: Product.IDValue?
    var description: String?
    var detail: String?

    var typeLocation: String?
    var city: String?
    var cep: String?
    var street: String?
    var number: String?
    var complement: String?
    var district: String?

    public func toModel() -> StatusHistory {
        let model = StatusHistory()
        
        model.id = id
//        model.history = history
        model.dtCreated = dtCreated
        model.$product.id = productId!
        model.description = description
        model.detail = detail

        model.unity.typeLocation = typeLocation
        model.unity.city = city
        model.unity.cep = cep
        model.unity.street = street
        model.unity.number = number
        model.unity.complement = complement
        model.unity.district = district

        return model
    }
    
    enum CodingKeys: String, CodingKey {
        case id, description, detail, city, cep, street, number, complement, district
        case dtCreated = "dt_created"
        case productId = "product_id"
        case typeLocation = "type_location"
    }
}
