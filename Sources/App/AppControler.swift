//
//  App.swift
//  backEnd_Macro
//
//  Created by Gustavo Horestee Santos Barros on 08/10/24.
//

import Fluent
import Vapor

enum App{
    enum Controller{
        case createOrder(CreateOrder)
        case createUser(CreateUser)
        case createUserApple(CreateUserToken)
        
        func boot(routes: RoutesBuilder){
            switch self {
            case .createOrder(let createOrder):
                routes.get("orders", use: createOrder.getAllOrders)
                routes.post("orders", use: createOrder.createOrder)
                routes.get("orders", "status", use: createOrder.verifyStatusOrders)
                routes.delete("orders", "deleteAllOrders", use: createOrder.deleteAllOrders)
                routes.delete("orders", "deleteOrder", ":id", use: createOrder.deleteEspecifiqueOrder)
                routes.put("orders", "updateOrder", ":id", use: createOrder.updateEspecifiqueOrder)
                
                //mudar depois essas rotas
                routes.post("users", "device", "token", use: createOrder.addTokenDevice)
                routes.put("users", "allowNotification", use: createOrder.sendNotification)
                routes.delete("users", "deleteAllUsers", use: createOrder.deleteAllUsers)
            case .createUser(let createUser):
                routes.post("users", "register", use: createUser.createUser)
                routes.post("users", "login", use: createUser.loginHandler)
                routes.get("users", use: createUser.allUsers)
                routes.get("users", "tokens", use: createUser.allTokens)
            case .createUserApple(let createUserApple):
                routes.post("users", "apple", use: createUserApple.acessWithApple)
//                routes.post("users", "device", "token", use: createUserApple.addTokenDevice)
            }
        }
    }
}
