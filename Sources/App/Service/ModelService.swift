//
//  ModelService.swift
//  backEnd_Macro
//
//  Created by Gustavo Horestee Santos Barros on 08/10/24.
//

import Fluent
import Vapor

final class ModelService {
    public func saveOrder(req: Request) async throws -> Order {
        /// Salva uma nova ordem no banco de dados.
        let userID = try req.auth.require(User.self).requireID()
        let newOrder = Order(orderID: userID)
        try await newOrder.save(on: req.db)
        return newOrder
    }
    
    public func saveProducts(orderID: Order.IDValue, req: Request, codeAndName: CodeAndName) async throws {
        /// Salva os produtos associados a uma ordem no banco de dados.
        let newProduct = Product(
            name: codeAndName.name,
            code: codeAndName.code,
            orderID: orderID
        )
        try await newProduct.save(on: req.db)
        
        try await saveStatusHistory(productID: newProduct.id!, req: req)
    }
    
    public func saveStatusHistory(productID: Product.IDValue, req: Request, event: Correios.Evento? = nil) async throws {
        /// Salva o histórico de status associado a um produto no banco de dados.
        
        let newStatusHistory = StatusHistory(
            historyDate: event?.dtHrCriado ?? Date().toISO8601String(),
            productID: productID,
            description: event?.descricao ?? "Codigo adicionado ao App",
            detail: event?.detalhe ,
            typeLocation: event?.unidade?.tipo,
            city: event?.unidade?.endereco.cidade,
            cep: event?.unidade?.endereco.cep,
            street: event?.unidade?.endereco.logradouro,
            number: event?.unidade?.endereco.numero,
            complement: event?.unidade?.endereco.complemento,
            district: event?.unidade?.endereco.bairro
        )
        
        try await newStatusHistory.save(on: req.db)
    }
    
    public func updateOrdersStatusCorreios(req: Request, status: Correios.Welcome) async throws {
        ///Atualiza o status de todas as ordens de acordo com as informações recebidas dos Correios.
        for objeto in status.objetos {
            guard let order = try await findOrderByCode(req: req, code: objeto.codObjeto) else {
                throw Api.OrderError.notFound
            }
            
            let products = try await order.$products.get(on: req.db)
            for product in products {
                try await updateProduct(req: req, product: product, objeto: objeto)
            }
            
            try await order.save(on: req.db)
        }
    }
    
    
    private func findOrderByCode(req: Request, code: String) async throws -> Order? {
        let userID = try getAuthenticatedUserID(req)

        return try await loadRelationshipValues(req: req)
            .join(Product.self, on: \Product.$order.$id == \Order.$id)
            .filter(Product.self, \.$code == code)
            .filter(Order.self, \Order.$isFinished == false)
            .filter(Order.self, \.$user.$id == userID) 
            .first()
    }
    
    private func updateProduct(req: Request, product: Product, objeto: Correios.Objeto) async throws {
        ///Atualiza informações do produto com base nos dados do objeto dos Correios.
        product.deliveryCompany = objeto.tipoPostal?.categoria
        product.dtPredicted = objeto.dtPrevista?.toISO8601Date() ?? nil
        
        for evento in objeto.eventos {
            try await updateProductStatus(req: req, product: product, event: evento)
        }
        
        try await product.save(on: req.db)
    }
    
    private func updateProductStatus(req: Request, product: Product, event: Correios.Evento) async throws {
        ///Verifica se o evento já existe no histórico do produto. Se não existir, cria um novo.
        let exists = try await StatusHistory.query(on: req.db)
            .filter(\StatusHistory.$product.$id == product.id!)
            .filter(\.$dtCreated == event.dtHrCriado?.toISO8601Date())
            .first()
        
        if exists == nil {
            try await self.saveStatusHistory(productID: product.id!, req: req, event: event)
        } else {
            print("Evento já existe para o produto \(product.id!) - \(product.name) - \(product.code)")
        }
    }
    
    
    public func loadRelationshipValues(req: Request) -> QueryBuilder<Order> {
        /// Carrega as ordens e suas relações (produtos e histórico de status).
        return Order.query(on: req.db)
            .with(\.$products) { product in
                product.with(\.$statusHistory)
            }
    }
    
    public func creatUser(req: Request, user: UserRecive) async throws -> User{
        if !user.password.elementsEqual(user.passwordConfirmation){
            throw Abort(.conflict, reason: "As senhas não conferem")
        }
        
        if let existingUser = try await User.query(on: req.db).filter(\.$email == user.email).first() {
            throw Abort(.conflict, reason: "O e-mail já está cadastrado")
        }
        
        let userEncryptedPassoword = try Bcrypt.hash(user.password)
        return User(name: user.name, email: user.email, password: userEncryptedPassoword, createdAt: Date.now)
    }
    
    
    public func getAuthenticatedUserID(_ req: Request) throws -> UUID {
        return try req.auth.require(User.self).requireID()
    }
}
