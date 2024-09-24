//
//  StatusHistory.swift
//  backEnd_Macro
//
//  Created by Gustavo Horestee Santos Barros on 24/09/24.
//

import Fluent

struct StatusHistoryMigration: AsyncMigration {
    func prepare(on database: Database) async throws {

        try await database.schema(StatusHistory.schema)
            .id()
            .field("history", .string)
            .field("history_date", .datetime)
            .field("product_id", .uuid, .references(Product.schema, "id", onDelete: .cascade))
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema(StatusHistory.schema).delete()
    }
}
