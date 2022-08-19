import Fluent
import Vapor

enum UploadFileErrors: Error {
    case exceedSize
    case badExtension

    public var errorDescription: String? {
          switch self {
          case .exceedSize:
              return NSLocalizedString("error ... image size should not exceed 1 mb", comment: "Exceed Size")
          case .badExtension:
              return NSLocalizedString("extension is not acceptable", comment: "Bad Extension")
          }
      }
}

struct FileController: RouteCollection {
    private let publicDirectory: String
    init(publicDirectory: String){
        self.publicDirectory = publicDirectory
    }

    func boot(routes: RoutesBuilder) throws {
        let uploadedFiles = routes.grouped("files")
        uploadedFiles.get(use: index)
        uploadedFiles.post(use: create)
        uploadedFiles.group(":fileID") { uploadedFile in
            uploadedFile.delete(use: delete)
        }
    }

    func index(req: Request) async throws -> [UploadedFile] {
        try await UploadedFile.query(on: req.db).all()
    }

    func create(req: Request) async throws -> View {
        struct Input: Content {
            var file: File
        }

        let input = try req.content.decode(Input.self)

        try validateFile(file: input.file)

        // Generate new Name
        let imageNewNameAndExtension = "\(UUID())"+".\(input.file.extension!.lowercased())"

        let path = publicDirectory + "UploadFiles/" + imageNewNameAndExtension

        // SwiftNIO File handle
        let handle = try await req.application.fileio.openFile(path: path, mode: .write, flags: .allowFileCreation(posixMode:0x744),eventLoop: req.eventLoop).get()

        // Save the file to the server
        req.application.fileio.write(fileHandle: handle, buffer: input.file.data, eventLoop: req.eventLoop).whenSuccess { _ in
            try? handle.close()
        }

        let uploadedFile =  UploadedFile(title: imageNewNameAndExtension)

        try await uploadedFile.save(on: req.db)
        return try await req.view.render("result", ["fileUrl": "UploadFiles/" + uploadedFile.title])
    }

    func validateFile(file: File) throws {
        if file.data.readableBytes > 1_000_000  {
            throw UploadFileErrors.exceedSize
        }

        if !["png", "jpeg", "jpg"].contains(file.extension?.lowercased()) {
            throw UploadFileErrors.badExtension
        }
    }

    func delete(req: Request) async throws -> HTTPStatus {
        guard let uploadedFile = try await UploadedFile.find(req.parameters.get("fileID"), on: req.db) else {
            throw Abort(.notFound)
        }
        try await uploadedFile.delete(on: req.db)
        return .noContent
    }
}
