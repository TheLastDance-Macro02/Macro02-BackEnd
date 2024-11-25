//
//  Enuns.swift
//  backEnd_Macro
//
//  Created by Gustavo Horestee Santos Barros on 23/09/24.
//

import Vapor
import Fluent

struct Api {
    enum OrderError: Error {
        case notFound
        case invalidCode
        case invalidCodeInCorreiosStandard
        case codeExistsInDatabase
        case invalidStatus
        case notExistCodes
        
        var localizedDescription: String {
            switch self {
            case .notFound:
                return "A ordem não foi encontrada."
            case .invalidCode:
                return "O código fornecido é inválido."
            case .invalidCodeInCorreiosStandard:
                return "O código não está no padrão Correios."
            case .codeExistsInDatabase:
                return "Este código já existe no banco de dados."
            case .invalidStatus:
                return "O status fornecido é inválido."
            case .notExistCodes:
                return "Não existem códigos disponíveis."
            }
        }
    }
    
    enum Carriers: String {
        case Correios = "Correios (Brazil Post)"
//        case Fedex
//        case Aliexpress
//        case Amazon
//        case DHL
//        case MercadoLivre = "mercadolivre"
//        case UPS = "ups"
//        case ALL = "all"
        
        static func from(string: String) -> Carriers? {
            return Carriers(rawValue: string)
        }
    }
}




