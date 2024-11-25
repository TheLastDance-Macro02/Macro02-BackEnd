//
//  ListCarrier.swift
//  backEnd_Macro
//
//  Created by Gustavo Horestee Santos Barros on 21/11/24.
//

import Vapor
import Fluent

final class ListCarrier: Model, @unchecked Sendable {
    static let schema: String = "ListCarrier"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "name")
    var name: String
    
    @Field(key: "country_code")
    var code: String
    
    init() {}
    
    init(id: UUID? = nil, name: String, code: String) {
        self.id = id
        self.name = name
        self.code = code
    }
}

extension ListCarrier{
    public func toDTO() -> AllCarriersDTO {
        .init(
            name: self.name,
            CountryName: self.code
        )
    }
}
