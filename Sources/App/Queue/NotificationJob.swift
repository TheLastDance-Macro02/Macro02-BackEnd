//
//  CleanupJob.swift
//  backEnd_Macro
//
//  Created by Gustavo Horestee Santos Barros on 06/11/24.
//

import Vapor
import Fluent
import Queues
import APNS
import VaporAPNS
import APNSCore

struct NotificationController: @unchecked Sendable{
    private let correiosService: CorreiosService
    private let modelService: ModelService
    
    init (){
        self.correiosService = CorreiosService()
        self.modelService = ModelService()
    }
    
    public func sendNotification(context: QueueContext) async throws {
        let db = context.application.db
        let users = try await User.query(on: db).all()
        print("Total users: \(users.count)")
        
        for user in users {
            Task {
                try await validateUsers(user: user, context: context)
            }
        }
    }
    
    private func validateUsers(user: User, context: QueueContext) async throws {
        print("USER: \(String(describing: user.id)) - \(user.name) - \(String(describing: user.sendNotification)) - \(String(describing: user.deviceToken))")
        if user.sendNotification == true {
            if let deviceToken = user.deviceToken {
                try await verifyStatus(user: user, context: context, deviceToken: deviceToken)
            } else {
                print("User \(user.name) does not have a device token.")
            }
        } else {
            print("User \(user.name) does not want notifications.")
        }
    }
    
    private func sendNotificationUser(context: QueueContext, deviceToken: String, user: User, mensgem: String) async throws {
        let alert = APNSAlertNotification(
            alert: .init(
                title: .raw("🔔 Status do Pedido"),
                subtitle: .raw(mensgem)
            ),
            expiration: .immediately,
            priority: .immediately,
            topic: "app.TLD-FrontEnd",
            payload: Payload(acme1: "1", acme2: 2)
        )
        
        print("ENVIANDO - \(user.name)")
        try await context.application.apns.client.sendAlertNotification(
            alert,
            deviceToken: deviceToken
        )
    }
    

    private func verifyStatus(user: User, context: QueueContext, deviceToken: String) async throws {
        let fakeRequest = Request(application: context.application, on: context.application.eventLoopGroup.next())
        
        let lastOrders = try await modelService.loadRelationshipValues(req: fakeRequest)
            .filter(\Order.$user.$id == user.requireID())
            .all()
        
        try await self.correiosService.verifyAllStatus(req: fakeRequest, modelService: self.modelService, userID: user.requireID())
        
        let newOrders = try await modelService.loadRelationshipValues(req: fakeRequest)
            .filter(\Order.$user.$id == user.requireID())
            .all()
        
        let updatedOrders = newOrders.compactMap { newOrder -> Order? in
            guard let oldOrder = lastOrders.first(where: { $0.id == newOrder.id }) else {
                return nil
            }
            
            let updatedProducts = newOrder.products.compactMap { newProduct -> Product? in
                guard let oldProduct = oldOrder.products.first(where: { $0.id == newProduct.id }) else {
                    return nil
                }
                
                if oldProduct.deliveryStatus != newProduct.deliveryStatus {
                    return newProduct
                }
                return nil
            }
            
            if !updatedProducts.isEmpty {
                let modifiedOrder = newOrder
                modifiedOrder.products = updatedProducts
                return modifiedOrder
            }
            return nil
        }
        
        if !updatedOrders.isEmpty{
            for order in updatedOrders {
                for product in order.products {
                    let mensagem = "Produto \(product.name) teve mudança de status para: \(product.deliveryStatus ?? "Sem status")"
                    try await sendNotificationUser(context: context, deviceToken: deviceToken, user: user, mensgem: mensagem)
                    print(mensagem)
                }
            }
        }else{
            try await sendNotificationUser(context: context, deviceToken: deviceToken, user: user, mensgem: "Seu pedido está a caminho! Notificaremos qualquer atualização importante.")
        }
    }

    
    private func createMockRequest(context: QueueContext) -> Request {
        let eventLoop = context.application.eventLoopGroup.next()
        let request = Request(application: context.application, on: eventLoop)
        return request
    }
}

struct NotificationJob: AsyncScheduledJob {
    private let notificationController = NotificationController()
    
    func run(context: QueueContext) async throws {
        try await notificationController.sendNotification(context: context)
    }
}

struct Notification: Codable {
    let title: String
    let body: String
}

struct Payload: Codable {
    let acme1: String
    let acme2: Int
}
