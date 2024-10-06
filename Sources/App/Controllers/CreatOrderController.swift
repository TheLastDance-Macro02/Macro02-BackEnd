//
//  CreatOrderController.swift
//  backEnd_Macro
//
//  Created by Gustavo Horestee Santos Barros on 26/09/24.
//

import Vapor
import Fluent



struct CreateOrder {
    
    @Sendable
    func getAllOrders(req: Request) async throws -> [OrderDTO] {
        /// Obtém todas as ordens, mapeando-as para DTOs.
        do {
            let res = try await loadRelationshipValues(req: req).all().map { $0.toDTO() }
            return res
        } catch {
            print("ERROR - getAllOrders: \(String(reflecting: error))")
            throw error
        }
    }
    
    @Sendable
    func getAllFinishesOrders(req: Request) async throws -> [OrderDTO] {
        // Obtém todas as ordens marcadas como favoritas, incluindo os produtos e o histórico de status.
        do {
            return try await Order.query(on: req.db)
                .filter(\.$isFinished == true)
                .with(\.$products) { product in
                    product.with(\.$statusHistory)
                }
                .all()
                .map { $0.toDTO() }
            
        } catch {
            print("ERROR - getAllFinishesOrders: \(String(reflecting: error))")
            throw error
        }
    }
    
    @Sendable
    func getSumaryOrders(req: Request) async throws -> [SumaryOrderDTO] {
        do {
            let orders = try await loadRelationshipValues(req: req).all()
            let sumaryOrder = orders.map {order in
                let sumaryProducts = order.products.map{ product in
                    SumaryProductDTO(
                        id: product.id!,
                        name: product.name,
                        code: product.code,
                        idOrder: order.id!,
                        status: product.deliveryStatus
                    )
                }
                return SumaryOrderDTO(id: order.id!, sumaryProducts: sumaryProducts)
            }
            
            return sumaryOrder
        }catch{
            print("ERROR in getSumaryOrders: \(error.localizedDescription)")
            throw error
        }
    }
    
    @Sendable
    func getSumaryOrdersFinished(req: Request) async throws -> [SumaryOrderDTO] {
        do {
            let orders = try await loadRelationshipValues(req: req).filter(\Order.$isFinished == true).all()
            let sumaryOrder = orders.map {order in
                let sumaryProducts = order.products.map{ product in
                    SumaryProductDTO(
                        id: product.id!,
                        name: product.name,
                        code: product.code,
                        idOrder: order.id!,
                        status: product.deliveryStatus
                    )
                }
                return SumaryOrderDTO(id: order.id!, sumaryProducts: sumaryProducts)
            }
            return sumaryOrder
        }catch{
            print("ERROR in getSumaryOrders: \(error.localizedDescription)")
            throw error
        }
    }
    
    @Sendable
    func getEspecificOrder(req: Request) async throws -> OrderDTO {
        do{
            guard let order = try await Order.find(req.parameters.get("id"), on: req.db) else {
                throw Abort(.notFound)
            }
            let loadRelationships = try await Order.query(on: req.db)
                .filter(\.$id == order.id!)
                .with(\.$products) { product in
                    product.with(\.$statusHistory)
                }
                .first()!
            
            return loadRelationships.toDTO()
        }catch{
            print("ERROR in getEspecificOrder: \(error.localizedDescription)")
            throw error
        }
    }
    
    //Verifica se e um codigo valido
    @Sendable
    func createOrder(req: Request) async throws -> OrderDTO {
        /// Cria uma nova ordem, salva os produtos e retorna a ordem criada com os produtos e histórico.
        let codeAndName = try req.content.decode(CodeAndName.self)
        try await verifyCode(code: codeAndName.code, req: req)
        let newOrder = try await saveOrder(req: req)
        try await saveProducts(orderID: newOrder.id!, req: req, codeAndName: codeAndName)
        return try await Order.query(on: req.db)
            .filter(\.$id == newOrder.id!)
            .with(\.$products) { product in
                product.with(\.$statusHistory)
            }
            .first()!
            .toDTO()
    }
    
    func verifyCode(code: String, req: Request) async throws {
        let regex = "^[A-Z]{2}\\d{9}[A-Z]{2}$"
            
        let isValid = NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: code)
        guard isValid else {
            throw OrderError.invalidCodeInCorreiosStandard
        }
        
        let exists = try await Product.query(on: req.db)
            .filter(\.$code == code)
            .first() != nil
        
        if exists {
            throw OrderError.codeExistsInDatabase
        }
        
        let response = try await requestStatusCorreios(req: req, urlString: "https://api.correios.com.br/srorastro/v1/objetos/\(code)?resultado=T", modelType: Correios.ErrorHandler.Error.self)
        
        if response.objetos.contains(where: { $0.mensagem == "SRO-020: Objeto não encontrado na base de dados dos Correios." }) {
            throw OrderError.invalidCode
        }
    }
    
    @Sendable
    func deleteAllOrders(req: Request) async throws -> HTTPStatus {
        /// Exclui todas as ordens no banco de dados.
        try await Order.query(on: req.db).delete()
        return .ok
    }
    
    
    @Sendable
    func verifyStatusOrders(req: Request) async throws -> [OrderDTO] {
        let orders = try await loadRelationshipValues(req: req).all()
        guard !orders.isEmpty else { throw OrderError.notExistCodes }
        let urlString = try await makeURlWithCodes(from: orders)
        let responseCorreios = try await requestStatusCorreios(req: req, urlString: urlString, modelType: Correios.Welcome.self)
        try await upadateOrdersStatus(req: req, status: responseCorreios)
        return try await loadRelationshipValues(req: req)
            .all()
            .map { $0.toDTO() }
    }
    
    private func upadateOrdersStatus(req: Request, status: Correios.Welcome) async throws {
        for objetos in status.objetos {
            let order = try await loadRelationshipValues(req: req)
                .join(Product.self, on: \Product.$order.$id == \Order.$id)
                .filter(Product.self, \.$code == objetos.codObjeto)
                .filter(Order.self, \Order.$isFinished == false)
                .first()
            
            guard let order = order else { throw OrderError.notFound }
            
            let products = try await order.$products.get(on: req.db)
            for product in products {
                product.deliveryCompany = objetos.tipoPostal.categoria
                product.dtPredicted = objetos.dtPrevista.toISO8601Date()
                for evento in objetos.eventos {
                    let exists = try await StatusHistory.query(on: req.db)
                    .filter(\StatusHistory.$product.$id == product.id!)
                    .filter(\.$dtCreated == evento.dtHrCriado.toISO8601Date())
                    .first()

                    // Se não existir, insere o novo status
                    if exists == nil {
                        try await saveStatusHistory(productID: product.id!, req: req, event: evento)
                    } else {
                        print("Evento já existe para o produto \(product.id!)")
                    }
                }
                try await product.save(on: req.db)
            }
            try await order.save(on: req.db)
        }
    }
    
    //verificar se for maior fazer alguma coisa
    private func makeURlWithCodes(from orders: [Order]) async throws -> String {
        let filteredProductCodes = orders.filter { !$0.isFinished }.flatMap { $0.products.map { $0.code } }
        if filteredProductCodes.count > 50 { return "" }
        let queryCodigos = filteredProductCodes.map { "codigosObjetos=\($0)" }.joined(separator: "&")
        return "https://api.correios.com.br/srorastro/v1/objetos?\(queryCodigos)&resultado=T"
    }
    
    private func requestTokemCorreios(req: Request) async throws -> Correios.Tokem {
        let response = try await req.client.post("https://api.correios.com.br/token/v1/autentica/cartaopostagem"){ req in
            req.headers.add(name: "Content-Type", value: "application/json")
            try req.content.encode(["numero":"0078781167"])
            req.headers.basicAuthorization = BasicAuthorization(username: "03731011000130", password: "CfI4wFFJOimCvlLZ4siY4EJOHEqLecjEflDdjfmF")
        }
        return try response.content.decode(Correios.Tokem.self)
    }
    
    ///"https://api.correios.com.br/srorastro/v1/objetos/\(code)?resultado=T" -> Um produto
    ///"https://api.correios.com.br/srorastro/v1/objetos?\(code)&resultado=T"  -> Varios produtos Array
    private func requestStatusCorreios<T: Codable>(req: Request, urlString: String, modelType: T.Type) async throws -> T {
        let tokem = try await requestTokemCorreios(req: req)
        let response = try await req.client.get("\(urlString)"){ req in
            req.headers.add(name: "Accept", value: "application/json")
            req.headers.add(name: "Authorization", value: "Bearer \(tokem.token)")
        }
        try checkResponse(response.status)
//        printWelcomeModel(try response.content.decode(T.self))
        return try response.content.decode(T.self)
    }
    
    private func checkResponse(_ response: HTTPStatus) throws {
        guard (200..<300).contains(response.code) else {
            throw OrderError.invalidCode
        }
    }
        
    
    //Front-End
    ///Quando o usuario entra no app, faz requisição de todas as orders.
    ///Ação realizada a cada minuto dentro do App.
    //Back-End
    ///Entra na rota de requisicao de todas as orders
    ///filtra por todas as orders ativas
    ///verifica o tamanho da listra filtrada
    ///gere o endPoint com base nos codigos filtrados
    ///faz a requisicao
    ///decode dos dados
    ///faz o update dos dados no banco
    ///retorna a lista de orders para o front
    
    
    //MARK: - Save data in model order
    private func saveOrder(req: Request) async throws -> Order {
        /// Salva uma nova ordem no banco de dados.
        let newOrder = Order()
        try await newOrder.save(on: req.db)
        return newOrder
    }
    
    private func saveProducts(orderID: Order.IDValue, req: Request, codeAndName: CodeAndName) async throws {
        /// Salva os produtos associados a uma ordem no banco de dados.
            let newProduct = Product(
                name: codeAndName.name,
                code: codeAndName.code,
                orderID: orderID
            )
            try await newProduct.save(on: req.db)
        
        try await saveStatusHistory(productID: newProduct.id!, req: req)
    }
    
    private func saveStatusHistory(productID: Product.IDValue, req: Request, event: Correios.Evento? = nil) async throws {
        /// Salva o histórico de status associado a um produto no banco de dados.

        // Cria uma nova instância de StatusHistory
        let newStatusHistory = StatusHistory(
//            history: event?.descricao,
            historyDate: event?.dtHrCriado ?? Date().toISO8601String(),
            productID: productID,
            description: event?.descricao,
            detail: event?.detalhe,
            typeLocation: event?.unidade.tipo,
            city: event?.unidade.endereco.cidade,
            cep: event?.unidade.endereco.cep,
            street: event?.unidade.endereco.logradouro,
            number: event?.unidade.endereco.numero,
            complement: event?.unidade.endereco.complemento,
            district: event?.unidade.endereco.bairro
        )

        // Salva a nova entrada de StatusHistory no banco de dados
        try await newStatusHistory.save(on: req.db)
    }
    
    func loadRelationshipValues(req: Request) -> QueryBuilder<Order> {
        /// Carrega as ordens e suas relações (produtos e histórico de status).
        return Order.query(on: req.db)
            .with(\.$products) { product in
                product.with(\.$statusHistory)
            }
    }
}
