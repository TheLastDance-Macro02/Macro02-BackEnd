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
//            .field("history", .string)
            .field("dt_created", .datetime)
            .field("description", .string)
            .field("detail", .string)
            .field("product_id", .uuid, .references(Product.schema, "id", onDelete: .cascade))
            .field("unity_type_location", .string)
            .field("unity_city", .string)
            .field("unity_cep", .string)
            .field("unity_street", .string)
            .field("unity_number", .string)
            .field("unity_complement", .string)
            .field("unity_district", .string)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema(StatusHistory.schema).delete()
    }
}
