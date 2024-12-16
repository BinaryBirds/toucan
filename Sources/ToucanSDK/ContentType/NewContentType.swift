//
//  File.swift
//  toucan
//
//  Created by Tibor Bodecs on 2024. 12. 16..
//

import Foundation

struct NewContentType: Codable {
    
    struct Property: Codable {
        let type: String?
        let required: Bool?
    }

    let id: String
    let location: String?
    let properties: [String: Property]?
    let html: NewHtml?
}

struct NewHtml: Codable {
    
    enum Join: String, Codable {
        case one
        case many
    }
    
    struct Formatter: Codable {
        let type: String
        let format: String
    }
    
    enum Order: String, Codable {
        case asc
        case desc
    }
    
    struct Reference: Codable {
        let references: String
        let join: Join
        let sort: String?
        let order: Order?
        let limit: Int?
    }
    
    struct ContextItem: Codable {
        let property: String?
        let relation: Reference?
        let formatter: Formatter?
    }
    
    enum Method: String, Codable {
        case equals
    }

    struct Filter: Codable {
        let field: String
        let method: Method
        let value: String
    }
    
    struct Query: Codable {
        let sort: String?
        let order: Order?
        let limit: Int?
        let filter: Filter?
    }

    struct Inject: Codable {
        let css: [String]?
        let js: [String]?
    }
    
    struct GlobalContext: Codable {
        let query: Query?
        let context: [String: ContextItem]?
    }
    
    struct ContentType: Codable {
        let query: Query?
        let context: [String: ContextItem]?
        let template: String?
        let output: String?
        let inject: Inject?
    }
    
    struct PageBundle: Codable {
        let context: [String: ContextItem]?
        let template: String?
        let inject: Inject?
    }

    let globalContext: [String: GlobalContext]?
    let contentType: ContentType?
    let pageBundle: PageBundle?
}



