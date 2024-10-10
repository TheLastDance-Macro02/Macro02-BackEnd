//
//  CreateUser.swift
//  backEnd_Macro
//
//  Created by Gustavo Horestee Santos Barros on 09/10/24.
//

import Vapor
import Fluent

struct CreateUser: @unchecked Sendable{
    private let modelService: ModelService
    
    init (){
        self.modelService = ModelService()
    }
    
    @Sendable
    func createUser(req: Request) async throws -> UserDTO{
        let user = try req.content.decode(User.self)
        let newUser = try await modelService.creatUser(req: req, user: user)
        
        return newUser.toPublicDTO()
    }
}
