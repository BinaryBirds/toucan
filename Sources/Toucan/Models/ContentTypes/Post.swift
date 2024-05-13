//
//  File.swift
//
//
//  Created by Tibor Bodecs on 03/05/2024.
//

import Foundation

struct Post: ContentType {
    let id: String
    let slug: String
    let metatags: Metatags
    let publication: Date
    let lastModification: Date
    let variables: [String: String]
    let markdown: String

    let authorIds: [String]
    let tagIds: [String]
}