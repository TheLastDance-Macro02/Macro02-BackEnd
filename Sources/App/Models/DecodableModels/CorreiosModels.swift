//
//  PostingCode.swift
//  backEnd_Macro
//
//  Created by Gustavo Horestee Santos Barros on 03/10/24.
//

import Foundation


enum Correios{
    struct PostingCode: Codable {
        let numero: String
    }
    
    struct Tokem: Codable {
        let token: String
    }
    
    struct Welcome: Codable {
        let objetos: [Objeto]
    }

    struct Objeto: Codable {
        let codObjeto: String
        let tipoPostal: TipoPostal?
        let dtPrevista: String?
        let eventos: [Evento]
    }

    struct Evento: Codable {
        let dtHrCriado, descricao: String?
        let detalhe: String?
        let unidade: Unidade?
    }

    struct Unidade: Codable {
        let tipo: String?
        let endereco: UnidadeEndereco
    }


    struct UnidadeEndereco: Codable {
        let cidade: String?
        let cep, logradouro, complemento, numero: String?
        let bairro: String?
    }


    struct TipoPostal: Codable {
        let categoria: String? 
    }
    
    enum ErrorHandler {
        struct Error: Codable {
            let versao: String
            let quantidade: Int
            let objetos: [Objeto]
            let tipoResultado: String
        }

        struct Objeto: Codable {
            let mensagem: String?
        }
    }
}
