//
//  File.swift
//  backEnd_Macro
//
//  Created by Gustavo Horestee Santos Barros on 01/10/24.
//

import Vapor

struct SumaryOrderDTO: Content {
    var id: UUID
    var sumaryProducts: [SumaryProductDTO]
}

struct SumaryProductDTO: Content {
    var id: UUID
    var name: String
    var code: String
    var idOrder: Order.IDValue
    var status: String?
}



