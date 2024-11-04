//
//  ProductMigration 2.swift
//  backEnd_Macro
//
//  Created by Gustavo Horestee Santos Barros on 11/10/24.
//


import Fluent

struct TokemMigration: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(Tokem.schema)
            .id()
            .field("tokem_value", .string, .required)
            .field("user_id", .uuid, .required, .references(User.schema, "id", onDelete: .cascade))
            .unique(on: "tokem_value")
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema(Tokem.schema).delete()
    }
}
