import NIOSSL
import Fluent
import FluentPostgresDriver
import Vapor
import JWT

import APNS
import VaporAPNS
import APNSCore

import Mailgun

public func configure(_ app: Application) async throws {
    
    if app.environment == .development {
        app.databases.use(DatabaseConfigurationFactory.postgres(configuration: .init(
            hostname: Environment.get("DATABASE_HOST") ?? "localhost",
            port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? SQLPostgresConfiguration.ianaPortNumber,
            username: Environment.get("admin_username") ?? "vapor_username",
            password: Environment.get("12345678") ?? "vapor_password",
            database: Environment.get("macro_database") ?? "vapor_database",
            tls: .prefer(try .init(configuration: .clientDefault)))
        ), as: .psql)
    }else{
        
        if let databaseURL = Environment.get("DATABASE_URL") {
            var tlsConfig: TLSConfiguration = .makeClientConfiguration()
            tlsConfig.certificateVerification = .none
            let nioSSLContext = try NIOSSLContext(configuration: tlsConfig)

            var postgresConfig = try SQLPostgresConfiguration(url: databaseURL)
            postgresConfig.coreConfiguration.tls = .require(nioSSLContext)

            app.databases.use(.postgres(configuration: postgresConfig), as: .psql)
        }
//        else {
//            app.databases.use(DatabaseConfigurationFactory.postgres(configuration: .init(
//                hostname: Environment.get("DATABASE_HOST") ?? "localhost",
//                port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? SQLPostgresConfiguration.ianaPortNumber,
//                username: Environment.get("admin_username") ?? "vapor_username",
//                password: Environment.get("12345678") ?? "vapor_password",
//                database: Environment.get("macro_database") ?? "vapor_database",
//                tls: .prefer(try .init(configuration: .clientDefault)))
//            ), as: .psql)
//        }
    }
    
    //Comentario de teste .....DNV.....
    let privateKey: String = """
    -----BEGIN PRIVATE KEY-----
    MIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQgzHHuODiKS0+g1IQC
    PjBgt0nTfqo9IVWc5bCN13YjXBagCgYIKoZIzj0DAQehRANCAARURwxjkbYvIrF9
    8WRy8G15KTHQxcEMnZ1pPAQQ1d/8EUndGCu69N/PPc9thWPyW8e1sPbf8eYRitD6
    pTb/wUM5
    -----END PRIVATE KEY-----
    """
    
    // Configure APNS using JWT authentication.
    let apnsConfig = APNSClientConfiguration(
        authenticationMethod: .jwt(
            privateKey: try .loadFrom(string: privateKey),
            keyIdentifier: "6VQL69CT52",
            teamIdentifier: "335BRL9A43"
        ),
        environment: .development
    )
    
    app.apns.containers.use(
        apnsConfig,
        eventLoopGroupProvider: .shared(app.eventLoopGroup),
        responseDecoder: JSONDecoder(),
        requestEncoder: JSONEncoder(),
        as: .default
    )
    
    app.migrations.add(UserMigration())
    app.migrations.add(TokemMigration())
    app.migrations.add(OrderMigration())
    app.migrations.add(ProductMigration())
    app.migrations.add(StatusHistoryMigration())
    app.migrations.add(AddFieldsToUser())
    
    
    app.queues.schedule(NotificationJob())
        .daily()
        .at(.noon)
    
    app.queues.schedule(NotificationJob())
        .daily()
        .at(21, 0)
    
    let now = Date()
    let twoMinutesLater = now.addingTimeInterval(1 * 1) 
    
    print(twoMinutesLater)
    app.queues.schedule(NotificationJob())
        .at(twoMinutesLater)
    
    await app.jwt.keys.add(hmac: "secret", digestAlgorithm: .sha256)
    app.jwt.apple.applicationIdentifier = "app.TLD-FrontEnd"
    app.mailgun.configuration = .init(apiKey: "9205d6d96d4257e29e98bdfb1227256e-79295dd0-228e2ab6")
    
    if app.environment == .development {
        try await app.autoMigrate()
        try app.queues.startScheduledJobs()
    }
    
    try routes(app)
}


