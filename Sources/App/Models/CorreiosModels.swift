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
        let objetos: [Objeto] //Sim
    }

    struct Objeto: Codable {
        let codObjeto: String // sim
        let tipoPostal: TipoPostal // sim //Trasnportadora
        let dtPrevista: String //dtPrevista sim
        let eventos: [Evento] //sim
    }

    struct Evento: Codable {
        let dtHrCriado, descricao: String //dtHrCriado, descricao sim
        let detalhe: String?// sim
        let unidade: Unidade // sim
    }

    struct Unidade: Codable {
        let tipo: String//sim
        let endereco: UnidadeEndereco//sim
    }


    struct UnidadeEndereco: Codable {
        let cidade: String// cidade
        let cep, logradouro, complemento, numero: String?//sim
        let bairro: String?//sim
    }


    struct TipoPostal: Codable {
        let categoria: String //categoria sim
    }
}
