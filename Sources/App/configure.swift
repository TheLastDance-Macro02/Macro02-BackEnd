import NIOSSL
import Fluent
import FluentPostgresDriver
import Vapor

public func configure(_ app: Application) async throws {
    
//    if let databaseURL = Environment.get("DATABASE_URL") {
//        var tlsConfig: TLSConfiguration = .makeClientConfiguration()
//        tlsConfig.certificateVerification = .none
//        let nioSSLContext = try NIOSSLContext(configuration: tlsConfig)
//
//        var postgresConfig = try SQLPostgresConfiguration(url: databaseURL)
//        postgresConfig.coreConfiguration.tls = .require(nioSSLContext)
//
//        app.databases.use(.postgres(configuration: postgresConfig), as: .psql)
//    } else {
        app.databases.use(DatabaseConfigurationFactory.postgres(configuration: .init(
            hostname: Environment.get("DATABASE_HOST") ?? "localhost",
            port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? SQLPostgresConfiguration.ianaPortNumber,
            username: Environment.get("admin_username") ?? "vapor_username",
            password: Environment.get("12345678") ?? "vapor_password",
            database: Environment.get("macro_database") ?? "vapor_database",
            tls: .prefer(try .init(configuration: .clientDefault)))
        ), as: .psql)
//    }

    app.migrations.add(OrderMigration())
    app.migrations.add(ProductMigration())
    app.migrations.add(StatusHistoryMigration())
    app.migrations.add(UserMigration())
    
    if app.environment == .development {
        try await app.autoMigrate()
    }

    
    try routes(app)
}
