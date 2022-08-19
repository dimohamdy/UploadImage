import Fluent
import Vapor

func routes(_ app: Application) throws {

    app.get { req async throws in
        try await req.view.render("index")
    }

    try app.register(collection: FileController(publicDirectory: app.directory.publicDirectory))
}
