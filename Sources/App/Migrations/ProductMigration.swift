//
//  ProductMigration.swift
//  backEnd_Macro
//
//  Created by Gustavo Horestee Santos Barros on 24/09/24.
//

import Fluent

struct ProductMigration: AsyncMigration {
    func prepare(on database: Database) async throws {
//       let status = try await EnumHelper.createDeliveryStatusEnum(on: database)
//       let company = try await EnumHelper.createCompanyEnum(on: database)
        
        try await database.schema(Product.schema)
            .id()
            .field("name", .string, .required)
            .field("code", .string, .required)
            .field("is_finished", .bool, .required, .sql(.default(false)))
            .field("order_id", .uuid, .references(Order.schema, "id", onDelete: .cascade))
            .field("delivery_status", .string)
            .field("delivery_company", .string)
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema(Product.schema).delete()
        
//        try await database.enum("delivery_company").delete()
//        try await database.enum("delivery_status").delete()
    }
}

