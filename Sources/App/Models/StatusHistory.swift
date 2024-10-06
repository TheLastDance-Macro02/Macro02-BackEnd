//
//  StatusHistory.swift
//  backEnd_Macro
//
//  Created by Gustavo Horestee Santos Barros on 23/09/24.
//

import Vapor
import Fluent

final class unity: Fields, @unchecked Sendable {
    @OptionalField(key: "type_location")
    var typeLocation: String?
    
    @OptionalField(key: "city")
    var city: String?
    
    @OptionalField(key: "cep")
    var cep: String?
    
    @OptionalField(key: "street")
    var street: String?
    
    @OptionalField(key: "number")
    var number: String?
    
    @OptionalField(key: "complement")
    var complement: String?
    
    @OptionalField(key: "district")
    var district: String?
    
    init(){}
}

final class StatusHistory: Model, @unchecked Sendable {
    static let schema: String = "status_history"
    
    @ID(key: .id)
    var id: UUID?
    
    @OptionalParent(key: "product_id")
    var product: Product?
    
//    @OptionalField(key: "history")
//    var history: String?
    
    @OptionalField(key: "dt_created")
    var dtCreated: Date?
    
    @OptionalField(key: "description")
    var description: String?
    
    @OptionalField(key: "detail")
    var detail: String?
    
    @Group(key: "unity")
    var unity: unity
    
    init() {}
    
    init(id: UUID? = nil,
//         history: String? = nil,
         historyDate: String? = nil,
         productID: Product.IDValue,
         description: String? = nil,
         detail: String? = nil,
         typeLocation: String? = nil,
         city: String? = nil,
         cep: String? = nil,
         street: String? = nil,
         number: String? = nil,
         complement: String? = nil,
         district: String? = nil) {
        
        self.id = id
//        self.history = history
        self.dtCreated = historyDate?.toISO8601Date()
        self.$product.id = productID
        self.description = description
        self.detail = detail
        
        self.unity.typeLocation = typeLocation
        self.unity.city = city
        self.unity.cep = cep
        self.unity.street = street
        self.unity.number = number
        self.unity.complement = complement
        self.unity.district = district
    }

}

extension StatusHistory {
    public func toDTO() -> StatusHistoryDTO {
        return .init(
            id: id,
//            history: history ?? "",
            dtCreated: dtCreated ?? Date(),
            productId: self.$product.id,
            description: description,
            detail: detail,
            typeLocation: unity.typeLocation,
            city: unity.city,
            cep: unity.cep,
            street: unity.street,
            number: unity.number,
            complement: unity.complement,
            district: unity.district
        )
    }
}
