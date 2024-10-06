//
//  Enuns.swift
//  backEnd_Macro
//
//  Created by Gustavo Horestee Santos Barros on 23/09/24.
//

import Vapor
import Fluent

struct Delivery {
    enum Company: String, CaseIterable, Codable {
        case correios = "correios"
        case aliexpress = "aliexpress"
        case shopee = "shopee"
        case mercadoLivre = "mercado_livre"
        case ups = "ups"
    }
    
    enum Status: String, CaseIterable, Codable {
        case pending = "pending"
        case inTransit = "in_transit"
        case outForDelivery = "out_for_delivery"
        case delivered = "delivered"
        case failed = "failed"
        case returned = "returned"
        case canceled = "canceled"
    }
}

struct Api {
    enum HttpMethods: String{
        case POST, PUT, DELETE, GET
    }

    enum MIME: String{
        case jsonAp = "application/json"
        case jsonType = "Content-Type"
    }
}

enum OrderError: Error {
    case notFound
    case invalidCode
    case invalidCodeInCorreiosStandard
    case codeExistsInDatabase
    case invalidStatus
    case notExistCodes
}

enum AppController{
    case createOrder(CreateOrder)
    
    func boot(routes: RoutesBuilder){
        switch self {
        case .createOrder(let createOrder):
            routes.get("orders", use: createOrder.getAllOrders)
            routes.get("orders", "finished", use: createOrder.getAllFinishesOrders)
            routes.get("orders", "getSumaryOrders", use: createOrder.getSumaryOrders)
            routes.get("orders", "getSumaryOrdersFinished", use: createOrder.getSumaryOrdersFinished)
            routes.get("orders", ":id", use: createOrder.getEspecificOrder)
            routes.post("orders", use: createOrder.createOrder)
            routes.get("orders", "status", use: createOrder.verifyStatusOrders)
            routes.delete("orders", "deleteAllOrders", use: createOrder.deleteAllOrders)//Deltar depois
        }
    }
}


