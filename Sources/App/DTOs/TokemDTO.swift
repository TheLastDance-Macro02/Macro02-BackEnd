//
//  TokemDTO.swift
//  backEnd_Macro
//
//  Created by Gustavo Horestee Santos Barros on 11/10/24.
//


import Foundation
import Vapor

struct TokemDTO: Content {
    var id: UUID?
    var tokemValue: String
    var userID: UUID?
    
    public func toModel() -> Tokem {
        return Tokem(
            id: id,
            tokemValue: tokemValue,
            userID: userID!
        )
    }
}
