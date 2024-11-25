//
//  CleanupJob.swift
//  backEnd_Macro
//
//  Created by Gustavo Horestee Santos Barros on 06/11/24.
//

import Vapor
import Fluent
import Queues

struct GetCarriersJobController: @unchecked Sendable{
    private let correiosService: CorreiosService
    private let modelService: ModelService
    private let allCarriers: AllCarriersService
    
    init (){
        self.correiosService = CorreiosService()
        self.modelService = ModelService()
        self.allCarriers = AllCarriersService()
    }
    
    public func requetAllCarriers(context: QueueContext) async throws {
        let fakeRequest = Request(application: context.application, on: context.application.eventLoopGroup.next())
        let response = try await self.allCarriers.requestAllCarriers(req: fakeRequest, modelType: AllCarriers.GetAllCarriers.self)
        
        for carrier in response.data {
            let existingCarrier = try await ListCarrier.query(on: context.application.db)
                .filter(\.$name == carrier.name)
                .filter(\.$code == carrier.code)
                .first()
            
            if existingCarrier == nil {
                let newCarrier = ListCarrier(name: carrier.name, code: carrier.code)
                try await newCarrier.save(on: context.application.db)
            } else {
                context.application.logger.info("Carrier já existe: \(carrier.name) - \(carrier.code)")
            }
        }
    }
}

struct GetCarriersJob: AsyncScheduledJob {
    private let getCarriersJobController = GetCarriersJobController()
    
    func run(context: QueueContext) async throws {
        try await getCarriersJobController.requetAllCarriers(context: context)
    }
}

