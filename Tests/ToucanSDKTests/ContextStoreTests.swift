//
//  File.swift
//  toucan
//
//  Created by Tibor Bodecs on 2024. 10. 13..
//

import Logging
import XCTest
@testable import ToucanSDK

final class ContextStoreTests: XCTestCase {

    func testContextStore() async throws {
        let logger = Logger(label: "test-logger")

        _ = ContextStore(
            source: .init(
                sourceUrl: URL(fileURLWithPath: "/"),
                config: .defaults,
                site: .defaults
            ),
            contentTypes: [
                .default,
                .author,
                .post,
            ],
            pageBundles: [
                .post1,
                .author1,
                .page1,
            ],
            blockDirectives: [],
            logger: logger
        )
    }
}
