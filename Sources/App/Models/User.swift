//
//  User.swift
//  backEnd_Macro
//
//  Created by Gustavo Horestee Santos Barros on 09/10/24.
//

import Fluent
import Vapor


final class User: Model, @unchecked Sendable {
    static let schema: String = "user"
    
    @Field(key: .id)
    var id: UUID?
    
    @Field(key: "name")
    var name: String
    
    @Field(key: "email")
    var email: String
    
    @Field(key: "password")
    var password: String
    
    @Field(key: "created_at")
    var createdAt: Date?
    
    @OptionalField(key: "sex")
    var sex: String?
    
    @OptionalField(key: "date_of_birth")
    var dateOfBirth: Date?
    
    @OptionalField(key: "location")
    var locationCoordinator: String?
    
    @Group(key: "unity")
    var unity: Unity

    init() { }
    
    init(id: UUID? = nil,
         name: String,
         email: String,
         password: String,
         sex: String? = nil,
         dateOfBirth: Date? = nil,
         location: String? = nil,
         createdAt: Date,
         typeLocation: String? = nil,
         city: String? = nil,
         cep: String? = nil,
         street: String? = nil,
         number: String? = nil,
         complement: String? = nil,
         district: String? = nil) {
        
        self.id = id
        self.name = name
        self.email = email
        self.password = password
        self.sex = sex
        self.dateOfBirth = dateOfBirth
        self.locationCoordinator = location
        self.createdAt = createdAt
        
        self.unity.typeLocation = typeLocation
        self.unity.city = city
        self.unity.cep = cep
        self.unity.street = street
        self.unity.number = number
        self.unity.complement = complement
        self.unity.district = district
    }
}

extension User {
    public func toDTO() -> UserDTO {
        return .init(
            id: id,
            name: name,
            email: email,
            password: password,
            sex: sex,
            dateOfBirth: dateOfBirth,
            locationCoordinator: locationCoordinator,
            createdAt: createdAt,
            typeLocation: unity.typeLocation,
            city: unity.city,
            cep: unity.cep,
            street: unity.street,
            number: unity.number,
            complement: unity.complement,
            district: unity.district
        )
    }
    
    public func toPublicDTO() -> UserDTO {
        return .init(
            id: id,
            name: name,
            email: email
        )
    }
}

//extension User: AsyncMiddleware {
//    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
//        
//    }
//}

