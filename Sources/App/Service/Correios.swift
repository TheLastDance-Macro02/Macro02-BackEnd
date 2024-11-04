//
//  ApiService.swift
//  backEnd_Macro
//
//  Created by Gustavo Horestee Santos Barros on 08/10/24.
//


import Vapor
import Fluent

//Coreios Endpoints
///"https://api.correios.com.br/srorastro/v1/objetos/\(code)?resultado=T" -> Requisitar um produto
///"https://api.correios.com.br/srorastro/v1/objetos?\(code)&resultado=T"  -> Requisitar varios produtos: [Codes]
///"https://api.correios.com.br/token/v1/autentica/cartaopostagem" -> Resquisitar tokem de acesso
class CorreiosService: ApiService{
    
    func makeURl(from orders: [Order]) async throws -> String{
        let filteredProductCodes = orders.filter { !$0.isFinished }.flatMap { $0.products.map { $0.code } }
        if filteredProductCodes.count > 50 { return "" } ///Iso vai da bo se o cara cadastrar mais de 50 produtos 😀
        let queryCodigos = filteredProductCodes.map { "codigosObjetos=\($0)" }.joined(separator: "&")
        if queryCodigos.isEmpty { return "ERROR" }
        return "https://api.correios.com.br/srorastro/v1/objetos?\(queryCodigos)&resultado=T"
    }
    
    func requestTokem<T: Codable>(req: Request) async throws -> T {
        let response = try await req.client.post("https://api.correios.com.br/token/v1/autentica/cartaopostagem"){ req in
            req.headers.add(name: "Content-Type", value: "application/json")
            try req.content.encode(["numero":"0078781167"])
            req.headers.basicAuthorization = BasicAuthorization(username: "03731011000130", password: "CfI4wFFJOimCvlLZ4siY4EJOHEqLecjEflDdjfmF")
        }
        return try response.content.decode(T.self)
    }
    
    func requestData<T: Codable>(req: Request, urlString: String, modelType: T.Type) async throws -> T {
        let tokem: Correios.Tokem = try await requestTokem(req: req)
        let response = try await req.client.get("\(urlString)"){ req in
            req.headers.add(name: "Accept", value: "application/json")
            req.headers.add(name: "Authorization", value: "Bearer \(tokem.token)")
        }
        try self.checkRespons(response.status)
        return try response.content.decode(T.self)
    }
    
    func verifyCode(code: String, req: Request) async throws {
        ///Verifica se o código do produto é válido e se já existe no banco de dados.
        let regex = "^[A-Z]{2}\\d{9}[A-Z]{2}$"
        let isValid = code.range(of: regex, options: .regularExpression) != nil
        
        if !isValid {
            throw Api.OrderError.invalidCode
        }
        
        let user = try req.auth.require(User.self)
        let userID = try user.requireID()

        let exists = try await Product.query(on: req.db)
            .join(Order.self, on: \Product.$order.$id == \Order.$id)
            .filter(Order.self, \Order.$user.$id == userID)
            .filter(\.$code == code)
            .first() != nil
        
        if exists {
            throw Api.OrderError.codeExistsInDatabase
        }
        
        let response = try await self.requestData(req: req, urlString: "https://api.correios.com.br/srorastro/v1/objetos/\(code)?resultado=T", modelType: Correios.ErrorHandler.Error.self)
        
        if response.objetos.contains(where: { $0.mensagem == "SRO-020: Objeto não encontrado na base de dados dos Correios." }) {
            throw Api.OrderError.invalidCode
        }
    }
}
