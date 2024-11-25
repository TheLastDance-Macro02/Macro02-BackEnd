//
//  ListCarrieMigrationr.swift
//  backEnd_Macro
//
//  Created by Gustavo Horestee Santos Barros on 21/11/24.
//

import Fluent

struct ListCarrieMigration: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(ListCarrier.schema)
            .id()
            .field("name", .string, .required)
            .field("country_code", .string, .required)
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema(ListCarrier.schema).delete()
    }
    
}


