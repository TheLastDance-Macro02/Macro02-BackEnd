

import Fluent
import Vapor

func routes(_ app: Application) throws {
    let createOrder = CreateOrder()
    let createUser = CreateUser()
    
    app.get { req async in
        "Servidor Rodando"
    }
    
    let basicAuthMiddleware = User.authenticator()
    let guardAuthMiddleware = User.guardMiddleware()
    
    let protectedOrderRoutes = app.grouped(basicAuthMiddleware, guardAuthMiddleware)
    
    App.Controller.createOrder(createOrder).boot(routes: protectedOrderRoutes)
    App.Controller.createUser(createUser).boot(routes: app.routes)
}
