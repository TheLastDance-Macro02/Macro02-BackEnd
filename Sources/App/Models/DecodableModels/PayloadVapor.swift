//
//  PayloadVapor.swift
//  backEnd_Macro
//
//  Created by Gustavo Horestee Santos Barros on 21/10/24.
//

import Vapor
import JWT

struct PayloadVapor: JWTPayload {
    var sub: SubjectClaim
    var exp: ExpirationClaim
    var admin: BoolClaim

    func verify(using key: some JWTAlgorithm) throws {
        try self.exp.verifyNotExpired()
    }
}

