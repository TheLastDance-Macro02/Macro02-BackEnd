//
//  OrdertMigration.swift
//  backEnd_Macro
//
//  Created by Gustavo Horestee Santos Barros on 24/09/24.
//


import Fluent

struct OrderMigration: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(Order.schema)
            .id()
            .field("is_favorite", .bool, .required, .sql(.default(false)))
            .field("is_finished", .bool, .required, .sql(.default(false)))
            .field("created_at", .datetime, .required, .sql(.default("CURRENT_TIMESTAMP")))
            .field("finished_at", .datetime)
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema(Order.schema).delete()
    }
}


