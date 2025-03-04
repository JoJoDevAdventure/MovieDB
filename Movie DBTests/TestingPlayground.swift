//
//  TestingPlayground.swift
//  Movie DBTests
//
//  Created by Jonas Frey on 25.04.22.
//  Copyright © 2022 Jonas Frey. All rights reserved.
//

import XCTest
@testable import Movie_DB
import CoreData

class TestingPlayground: XCTestCase {
    func testPlayground() async throws {
        _ = try await TMDBAPI.shared.media(
            for: 1399,
            type: .show,
            context: PersistenceController.createDisposableContext()
        )
    }
}
