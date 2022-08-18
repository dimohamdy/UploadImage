//
//  CreateFile.swift
//  
//
//  Created by BinaryBoy on 8/16/22.
//

import Foundation
import Fluent

struct CreateFile: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("files")
            .id()
            .field("title", .string, .required)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("files").delete()
    }
}
