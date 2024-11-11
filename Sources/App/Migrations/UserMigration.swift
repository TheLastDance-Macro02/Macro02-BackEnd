//
//  UserMigration.swift
//  backEnd_Macro
//
//  Created by Gustavo Horestee Santos Barros on 09/10/24.
//

import Fluent

struct UserMigration: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(User.schema)
            .id()
            .field("name", .string, .required)
            .field("email", .string, .required)
            .field("password", .string, .required)
            .field("phone_number", .string)
            .field("created_at", .datetime)
            .field("gender", .string)
            .field("date_of_birth", .datetime)
            .field("location", .string)
            .field("unity_type_location", .string)
            .field("unity_city", .string)
            .field("unity_cep", .string)
            .field("unity_street", .string)
            .field("unity_number", .string)
            .field("unity_complement", .string)
            .field("unity_district", .string)
            .unique(on: "email")
            .create()
    }

    
    func revert(on database: Database) async throws {
        try await database.schema(User.schema).delete()
    }
}

struct AddFieldsToUser: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(User.schema)
            .field("device_token", .string)
            .field("send_notification", .bool)
            .field("user_image", .data)
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema(User.schema)
            .deleteField("device_token")
            .deleteField("send_notification")
            .deleteField("user_image")
            .update()
    }
}
