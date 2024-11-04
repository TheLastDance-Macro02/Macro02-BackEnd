//
//  CreateUser.swift
//  backEnd_Macro
//
//  Created by Gustavo Horestee Santos Barros on 09/10/24.
//

import Vapor
import Fluent
//import JWTKit

struct CreateUser: @unchecked Sendable{
    private let modelService: ModelService
    
    init (){
        self.modelService = ModelService()
    }
    
    @Sendable
    func createUser(req: Request) async throws -> UserDTO{
        let user = try req.content.decode(UserRecive.self)
        let newUser = try await modelService.creatUser(req: req, user: user)
        try await newUser.save(on: req.db)
        return newUser.toPublicDTO()
    }
    
    
    @Sendable
    func loginHandler(req: Request) async throws -> TokemDTO {
        let user = try req.auth.require(User.self)
        
        guard let userId = user.id else {
            throw Abort(.internalServerError, reason: "ID do usuário não encontrado")
        }
        
        // Verifica se o usuário existe e busca token existente
        if let existingUser = try await User.find(userId, on: req.db) {
            // Busca token existente com eager loading do usuário
            if let existingToken = try await Tokem.query(on: req.db)
                .filter(\.$userID.$id == existingUser.id!)
                .with(\.$userID)
                .first() {
                return existingToken.toDTO()
            }
            
            // Se não encontrou token, cria um novo
            let newToken = try Tokem.generateToken(for: existingUser)
            try await newToken.save(on: req.db)
            return newToken.toDTO()
        }
        
        // Se chegou aqui, algo está errado pois o usuário autenticado não existe no banco
        throw Abort(.internalServerError, reason: "Usuário autenticado não encontrado no banco de dados")
    }
    
    @Sendable
    func allUsers(req: Request) async throws -> [UserDTO] {
        try await User.query(on: req.db).all().map {
            $0.toPublicDTO()
        }
    }
    
    @Sendable
    func allTokens(req: Request) async throws -> [TokemDTO] {
        try await Tokem.query(on: req.db).all().map {
            $0.toDTO()
        }
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
                    // Se não encontrar o token, cria um novo
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
}
