import Fluent

struct OrderMigration: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(Order.schema)
            .id()
            .field("is_favorite", .bool)
            .field("is_finished", .bool)
//            .field()
            .field("created_at", .datetime, .required)
            .field("finished_at", .datetime)
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema(Order.schema).delete()
    }
}
