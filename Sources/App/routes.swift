import Fluent
import Vapor

func routes(_ app: Application) throws {
    app.get { req async in
        "adjskgljhlkjfsgln sdjkhlfk"
    }

    app.get("hello") { req async -> String in
        "salveeee porrra"
    }
    
    app.get("ponde") { req async -> String in
        "bla bla bla bla bla"
    }

//    try app.register(collection: TodoController())
}
