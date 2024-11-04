

import Fluent
import Vapor

func routes(_ app: Application) throws {
    let createOrder = CreateOrder()
    let createUser = CreateUser()
    
    app.get { req async in
        "Servidor Rodando"
    }
    
    //Autenticar user
    let basicAuthMiddleware = User.authenticator()
    let protectedUserRoutes = app.grouped(basicAuthMiddleware)
    
    //Autenticar order
    let tokenAuthMiddleware = Tokem.authenticator()
    let protectedOrderRoutes = app.grouped(tokenAuthMiddleware, basicAuthMiddleware)
    
    App.Controller.createUser(createUser).boot(routes: protectedUserRoutes)
    App.Controller.createOrder(createOrder).boot(routes: protectedOrderRoutes)
}
