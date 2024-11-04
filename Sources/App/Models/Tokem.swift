//
//  Tokem.swift
//  backEnd_Macro
//
//  Created by Gustavo Horestee Santos Barros on 11/10/24.
//

import Vapor
import Fluent

final class Tokem: Model, @unchecked Sendable {
    static let schema: String = "tokem"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "tokem_value")
    var tokemValue: String
    
//    @Field(key: "tokem_expiration")
//    var tokemExpiration: Date
    
    @Parent(key: "user_id")
    var userID: User
    
    init() {}
    
    init(id: UUID? = nil, tokemValue: String, userID: User.IDValue/*, tokenExpiration: Date*/) {
        self.id = id
        self.tokemValue = tokemValue
        self.$userID.id = userID
//        self.
    }
}

extension Tokem {
    func toDTO() -> TokemDTO {
        return TokemDTO(
            id: self.id,
            tokemValue: self.tokemValue,
            userID: self.$userID.id
        )
    }
}

extension Tokem{
    static func generateToken(for user: User) throws -> Tokem {
        let randonTokem = [UInt8].random(count: 64).base64
        return try Tokem(tokemValue: randonTokem, userID: user.requireID())
    }
}


extension Tokem: ModelTokenAuthenticatable{
    static let valueKey = \Tokem.$tokemValue
    static let userKey = \Tokem.$userID
    
    var isValid: Bool {
        true
    }
}



