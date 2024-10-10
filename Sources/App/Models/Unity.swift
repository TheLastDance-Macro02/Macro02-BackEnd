//
//  Unity.swift
//  backEnd_Macro
//
//  Created by Gustavo Horestee Santos Barros on 08/10/24.
//

import Vapor
import Fluent

final class Unity: Fields, @unchecked Sendable {
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
