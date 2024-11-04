//
//  UserDTO.swift
//  backEnd_Macro
//
//  Created by Gustavo Horestee Santos Barros on 09/10/24.
//

import Fluent
import Vapor

struct UserDTO: Content {
    var id: UUID?
    var name: String
    var email: String
    var password: String?
    var passwordConfirmation: String?
    var phoneNumber: String?
    var gender: String?
    var dateOfBirth: Date?
    var locationCoordinator: String?
    var createdAt: Date?
    
    var typeLocation: String?
    var city: String?
    var cep: String?
    var street: String?
    var number: String?
    var complement: String?
    var district: String?

    var tokemDTO: TokemDTO?
    
    public func toModel() -> User {
        return User(
            id: id,
            name: name,
            email: email,
            password: password!,
            phoneNumber: phoneNumber!,
            gender: gender,
            dateOfBirth: dateOfBirth,
            location: locationCoordinator,
            createdAt: createdAt!,
            typeLocation: typeLocation,
            city: city,
            cep: cep,
            street: street,
            number: number,
            complement: complement,
            district: district
        )
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case email
        case password
        case gender
        case dateOfBirth = "date_of_birth"
        case locationCoordinator = "location"
        case createdAt = "created_at"
        case typeLocation = "type_location"
        case phoneNumber = "phone_number"
        case city
        case cep
        case street
        case number
        case complement
        case district
    }
}

struct UserRecive: Content {
    let email: String
    let name: String
    let password: String
    let passwordConfirmation: String
}

extension UserRecive: Validatable{
    static func validations(_ validations: inout Vapor.Validations) {
        validations.add(
            "email",
            as: String.self,
            is: .email
        )
        validations.add(
            "name",
            as: String.self,
            is: !.empty && .count(3..<250) && .alphanumeric,
            customFailureDescription: "Provided username is invalid!"
        )
    }
}

extension ValidatorResults {
    public struct PasswordMatch {
        public let areEqual: Bool
    }
}




