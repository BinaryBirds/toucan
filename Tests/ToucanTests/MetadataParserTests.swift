//
//  File.swift
//
//
//  Created by Tibor Bodecs on 03/05/2024.
//

import XCTest
@testable import Toucan

final class MetadataParserTests: XCTestCase {

    func testBasics() throws {

        let input = #"""
            ---
            slug: lorem-ipsum
            title: Lorem ipsum
            tags: foo, bar, baz
            ---

            Lorem ipsum dolor sit amet.
            """#

        let parser = MetadataParser()
        let metadata = parser.parse(markdown: input)

        let expectation: [String: String] = [
            "slug": "lorem-ipsum",
            "title": "Lorem ipsum",
            "tags": "foo, bar, baz",
        ]

        XCTAssertEqual(metadata, expectation)
    }

}
