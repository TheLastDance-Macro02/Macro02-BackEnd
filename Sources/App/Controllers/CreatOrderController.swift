//
//  CreatOrderController.swift
//  backEnd_Macro
//
//  Created by Gustavo Horestee Santos Barros on 26/09/24.
//

import Vapor
import Fluent



struct CreateOrder {
    private let apiService: ApiService = ApiService.shared
    ///fazer rota /auth/callback do mercadolivre autenticar
    
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
    
    @Sendable
    func createOrder(req: Request) async throws -> OrderDTO {
        /// Cria uma nova ordem, salva os produtos e retorna a ordem criada com os produtos e histórico.
        let orderDTO = try req.content.decode(OrderDTO.self)
        let newOrder = try await saveOrder(req: req, orderDTO: orderDTO)
        try await saveProducts(order: newOrder, products: orderDTO.products, req: req)
        
        return try await Order.query(on: req.db)
            .filter(\.$id == newOrder.id!)
            .with(\.$products) { product in
                product.with(\.$statusHistory)
            }
            .first()!
            .toDTO()
    }
    
    @Sendable
    func deleteAllOrders(req: Request) async throws -> HTTPStatus {
        /// Exclui todas as ordens no banco de dados.
        try await Order.query(on: req.db).delete()
        return .ok
    }
    
    @Sendable
    func verifyOrderStatus(req: Request) async throws -> OrderDTO {
        guard let order = try await Order.find(req.parameters.get("id"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        let loadRelationships = try await Order.query(on: req.db)
            .filter(\.$id == order.id!)
            .with(\.$products) { product in
                product.with(\.$statusHistory)
            }
            .first()!
        
        let tokem = try await requestTokemCorreios(req: req)
        
        let codigosObjetos = ["AC128351367BR", "AC128351367BR", "AC128351367BR", "AC128351367BR"]
        let queryCodigos = codigosObjetos.map { "codigosObjetos=\($0)" }.joined(separator: "&")
        
        try await requestStatusCorreios(req: req, urlString: "AC128351367BR", tokem: tokem)
        
        
        return loadRelationships.toDTO()
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
    private func requestStatusCorreios(req: Request, urlString: String, tokem: Correios.Tokem) async throws {
        let response = try await req.client.get("\(urlString)"){ req in
            req.headers.add(name: "Accept", value: "application/json")
            req.headers.add(name: "Authorization", value: "Bearer \(tokem.token)")
        }
        let json = try response.content.decode(Correios.Welcome.self)
        printWelcomeModel(json)
    }
    
    func printWelcomeModel(_ welcome: Correios.Welcome) {
        print("Objetos:")
        for (index, objeto) in welcome.objetos.enumerated() {
            print("  Objeto \(index + 1):")
            print("    Código: \(objeto.codObjeto)")
            print("    Tipo Postal:")
            print("      Categoria: \(objeto.tipoPostal.categoria)")
            print("    Data Prevista: \(objeto.dtPrevista)")
            print("    Eventos:")
            for (eventIndex, evento) in objeto.eventos.enumerated() {
                print("      Evento \(eventIndex + 1):")
                print("        Data/Hora: \(evento.dtHrCriado)")
                print("        Descrição: \(evento.descricao)")
                if let detalhe = evento.detalhe {
                    print("        Detalhe: \(detalhe)")
                }
                print("        Unidade:")
                print("          Tipo: \(evento.unidade.tipo)")
                print("          Endereço:")
                print("            Cidade: \(evento.unidade.endereco.cidade)")
                if let cep = evento.unidade.endereco.cep {
                    print("            CEP: \(cep)")
                }
                if let logradouro = evento.unidade.endereco.logradouro {
                    print("            Logradouro: \(logradouro)")
                }
                if let complemento = evento.unidade.endereco.complemento {
                    print("            Complemento: \(complemento)")
                }
                if let numero = evento.unidade.endereco.numero {
                    print("            Número: \(numero)")
                }
                if let bairro = evento.unidade.endereco.bairro {
                    print("            Bairro: \(bairro)")
                }
            }
            print() 
        }
    }
    
    //MARK: - Save data in model order
    private func saveOrder(req: Request, orderDTO: OrderDTO) async throws -> Order {
        /// Salva uma nova ordem no banco de dados.
        let newOrder = Order(
            isFavorite: orderDTO.isFavorite,
            isFinished: orderDTO.isFinished,
            orderFinishedDate: orderDTO.orderFinishedAt
        )
        try await newOrder.save(on: req.db)
        return newOrder
    }
    
    private func saveProducts(order: Order, products: [ProductDTO], req: Request) async throws {
        /// Salva os produtos associados a uma ordem no banco de dados.
        for productDTO in products {
            let newProduct = Product(
                name: productDTO.name,
                code: productDTO.code,
                isFinished: productDTO.isFinished,
                orderID: order.id!,
                deliveryStatus: productDTO.deliveryStatus,
                deliveryCompany: productDTO.deliveryCompany
            )
            try await newProduct.save(on: req.db)
            try await saveStatusHistory(product: newProduct, statusHistory: productDTO.statusHistory, req: req)
        }
    }
    
    private func saveStatusHistory(product: Product, statusHistory: [StatusHistoryDTO], req: Request) async throws {
        /// Salva o histórico de status associado a um produto no banco de dados.
        for statusHistoryDTO in statusHistory {
            let newStatusHistory = StatusHistory(
                history: statusHistoryDTO.history,
                historyDate: statusHistoryDTO.historyDate,
                productID: product.id!
            )
            try await newStatusHistory.save(on: req.db)
        }
    }
    
    func loadRelationshipValues(req: Request) -> QueryBuilder<Order> {
        /// Carrega as ordens e suas relações (produtos e histórico de status).
        return Order.query(on: req.db)
            .with(\.$products) { product in
                product.with(\.$statusHistory)
            }
    }
}
