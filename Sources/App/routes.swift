import Fluent
import Vapor

func routes(_ app: Application) throws {
    let createOrder = CreateOrder()
    
    app.get { req async in
        "Servidor Rodando"
    }
    
    AppController.createOrder(createOrder).boot(routes: app.routes)
    
//    try app.register(collection: OrderController())
}
