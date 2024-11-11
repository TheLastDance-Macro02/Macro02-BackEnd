//
//  CreateUser 2.swift
//  backEnd_Macro
//
//  Created by Gustavo Horestee Santos Barros on 07/11/24.
//


import Vapor
import Fluent
//import JWTKit

struct CreateUserToken: @unchecked Sendable{
    private let modelService: ModelService
    
    init (){
        self.modelService = ModelService()
    }
    
    @Sendable
    func acessWithApple(req: Request) async throws -> TokemDTO {
        let token = try await req.jwt.apple.verify()
        let user = try req.content.decode(SignInWithApple.self)
        
        guard let email = token.email else {
            throw Abort(.badRequest, reason: "Email não encontrado no token")
        }
        
        let existingUser = try await User.query(on: req.db)
            .filter(\.$email == email)
            .first()
        
        if let existingUser = existingUser {
            // User existe
            guard let userToken = try await Tokem.query(on: req.db)
                .filter(\.$userID.$id == existingUser.id!)
                .with(\.$userID)
                .first() else {
                    let newToken = try Tokem.generateToken(for: existingUser)
                    try await newToken.save(on: req.db)
                    return newToken.toDTO()
            }
            
            print("Retornando Tokem: ", userToken.tokemValue)
            return userToken.toDTO()
        }
        
        // User não existe
        let newUser = User(
            name: user.name ?? "Unknown",
            email: email,
            password: UUID().uuidString,
            createdAt: Date()
        )
        
        try await newUser.save(on: req.db)
        
        let userToken = try Tokem.generateToken(for: newUser)
        try await userToken.save(on: req.db)
        
        print("Retornando Tokem: ", userToken.tokemValue)
        return userToken.toDTO()
    }
    
//    @Sendable
//    func addTokenDevice(req: Request) async throws -> HTTPStatus{
//        let userID = try req.auth.require(User.self).requireID()
//        print("UserID: \(userID)")
//        return .ok
//    }
}
