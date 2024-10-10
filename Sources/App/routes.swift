

import Fluent
import Vapor

func routes(_ app: Application) throws {
    let createOrder = CreateOrder()
    let createUser = CreateUser()
    
    app.get { req async in
        "Servidor Rodando"
    }
    
    App.Controller.createOrder(createOrder).boot(routes: app.routes)
    App.Controller.createUser(createUser).boot(routes: app.routes)
}
