

import Fluent
import Vapor

func routes(_ app: Application) throws {
    let correiosService: CorreiosService = CorreiosService()
    let modelService: ModelService = ModelService()
    
    let createOrder = CreateOrder(correiosService: correiosService, modelService: modelService)
    let createUser = CreateUser()
    let createUserApple = CreateUserToken()
    
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
    App.Controller.createUserApple(createUserApple).boot(routes: app.routes)
    App.Controller.createOrder(createOrder).boot(routes: protectedOrderRoutes)
}
