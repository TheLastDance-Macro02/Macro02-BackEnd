//
//  Extensions.swift
//  backEnd_Macro
//
//  Created by Gustavo Horestee Santos Barros on 22/09/24.
//


struct Api {
    enum HttpMethods: String{
        case POST, PUT, DELETE, GET
    }

    enum MIME: String{
        case jsonAp = "application/json"
        case jsonType = "Content-Type"
    }
}
