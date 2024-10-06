//
//  DateFormatterHelper.swift
//  backEnd_Macro
//
//  Created by Gustavo Horestee Santos Barros on 05/10/24.
//


import Foundation

extension String {
    /// Converte uma string no formato ISO 8601 para uma data
    func toISO8601Date() -> Date? {
        let isoFormatter = ISO8601DateFormatter()
        // Tenta converter a string para uma data
        return isoFormatter.date(from: self)
    }
}

extension Date {
    /// Converte uma data para string no formato ISO 8601
    func toISO8601String() -> String {
        let isoFormatter = ISO8601DateFormatter()
        return isoFormatter.string(from: self)
    }
}
