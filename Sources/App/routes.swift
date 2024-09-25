import Fluent
import Vapor

func routes(_ app: Application) throws {
    app.get { req async in
        "Servidor Rodando"
    }
    
    try app.register(collection: OrderController())
}
