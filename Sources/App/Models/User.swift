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
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "name")
    var name: String
    
    @Field(key: "email")
    var email: String
    
    @Field(key: "password")
    var password: String
    
    @Field(key: "created_at")
    var createdAt: Date?
    
    @Children(for: \.$user)
    var orders: [Order]
    
    @OptionalField(key: "phone_number")
    var phoneNumber: String?
    
    @OptionalField(key: "gender")
    var gender: String?
    
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
         phoneNumber: String? = nil,
         gender: String? = nil,
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
        self.phoneNumber = phoneNumber
        self.name = name
        self.email = email
        self.password = password
        self.gender = gender
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
            phoneNumber: phoneNumber,
            gender: gender,
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
}

extension User: ModelAuthenticatable {
    static let usernameKey = \User.$email
    static let passwordHashKey = \User.$password
    
    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.password)
    }
}

extension User {
    public func toPublicDTO() -> UserDTO {
        
        return .init(
            id: id,
            name: name,
            email: email
        )
    }
}




