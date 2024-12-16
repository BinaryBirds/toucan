//
//  File.swift
//  toucan
//
//  Created by Tibor Bodecs on 18/07/2024.
//

//import Foundation
//
//struct ContentType: Codable {
//    let id: String
//    let api: String?
//    let rss: Bool?
//    let location: String?
//    let template: String?
//    let css: [String]?
//    let js: [String]?
//    let pagination: Pagination?
//    let properties: [String: Property]?
//    let relations: [String: Relation]?
//    let context: Context?
//}
//
//extension ContentType {
//
//    var propertyKeys: [String] {
//        properties?.keys.sorted() ?? []
//    }
//
//    var relationKeys: [String] {
//        relations?.keys.sorted() ?? []
//    }
//}
//
//extension ContentType {
//
//    static let `default` = ContentType(
//        id: "page",
//        api: nil,
//        rss: nil,
//        location: nil,
//        template: "pages.default",
//        css: nil,
//        js: nil,
//        pagination: nil,
//        properties: [:],
//        relations: nil,
//        context: .init(
//            site: [
//                "pages": .init(
//                    sort: "title",
//                    order: .asc,
//                    limit: nil,
//                    filter: nil
//                )
//            ],
//            local: nil
//        )
//    )
//
//    static let pagination = ContentType(
//        id: "pagination",
//        api: nil,
//        rss: nil,
//        location: nil,
//        template: "pages.default",
//        css: nil,
//        js: nil,
//        pagination: nil,
//        properties: nil,
//        relations: nil,
//        context: .init(
//            site: [:],
//            local: nil
//        )
//    )
//}
//
//extension ContentType {
//
//    enum Order: String, Codable {
//        case asc
//        case desc
//    }
//}
//
//extension ContentType {
//
//    enum Join: String, Codable {
//        case one
//        case many
//    }
//}
//
//extension ContentType {
//
//    struct Pagination: Codable {
//        let bundle: String
//        let limit: Int
//        let sort: String?
//        let order: Order?
//    }
//}
//
//extension ContentType {
//
//    struct Property: Codable {
//
//        enum DataType: String, Codable, CaseIterable {
//            case string
//            case int
//            case double
//            case bool
//            case date
//        }
//
//        enum DefaultValue: Codable {
//            case string(String)
//            case int(Int)
//            case double(Double)
//            case bool(Bool)
//            case date(Date)
//
//            func encode(to encoder: Encoder) throws {
//                var container = encoder.singleValueContainer()
//                switch self {
//                case .string(let value):
//                    try container.encode(value)
//                case .int(let value):
//                    try container.encode(value)
//                case .double(let value):
//                    try container.encode(value)
//                case .bool(let value):
//                    try container.encode(value)
//                case .date(let value):
//                    try container.encode(value)
//                }
//            }
//
//            private static func decode<T: Decodable>(
//                _ type: T.Type,
//                from container: SingleValueDecodingContainer
//            ) -> T? {
//                return try? container.decode(type)
//            }
//
//            static func decode(
//                from decoder: Decoder,
//                as desiredType: ContentType.Property.DataType
//            ) throws -> ContentType.Property.DefaultValue {
//                let container = try decoder.singleValueContainer()
//
//                switch desiredType {
//                case .bool:
//                    if let value = decode(Bool.self, from: container) {
//                        return .bool(value)
//                    }
//                case .int:
//                    if let value = decode(Int.self, from: container) {
//                        return .int(value)
//                    }
//                case .double:
//                    if let value = decode(Double.self, from: container) {
//                        return .double(value)
//                    }
//                case .date:
//                    if let value = decode(Date.self, from: container) {
//                        return .date(value)
//                    }
//                case .string:
//                    if let value = decode(String.self, from: container) {
//                        return .string(value)
//                    }
//                }
//
//                throw DecodingError.dataCorruptedError(
//                    in: container,
//                    debugDescription: "Unable to decode value as \(desiredType)"
//                )
//            }
//
//            init(from decoder: Decoder) throws {
//                throw DecodingError.typeMismatch(
//                    Self.self,
//                    DecodingError.Context(
//                        codingPath: decoder.codingPath,
//                        debugDescription:
//                            "Use the `decode(from:as:)` method to decode with a specified type."
//                    )
//                )
//            }
//
//            func value<T>() -> T? {
//                switch self {
//                case .bool(let value):
//                    return value as? T
//                case .int(let value):
//                    return value as? T
//                case .double(let value):
//                    return value as? T
//                case .string(let value):
//                    return value as? T
//                case .date(let value):
//                    return value as? T
//                }
//            }
//        }
//
//        let type: DataType
//        let defaultValue: DefaultValue?
//
//        init(from decoder: Decoder) throws {
//            let container = try decoder.container(keyedBy: CodingKeys.self)
//
//            self.type = try container.decode(DataType.self, forKey: .type)
//            self.defaultValue = try? DefaultValue.decode(
//                from: decoder,
//                as: self.type
//            )
//        }
//    }
//}
//
//extension ContentType {
//
//    struct Relation: Codable {
//        let references: String
//        let join: Join
//        let sort: String?
//        let order: Order?
//        let limit: Int?
//    }
//}
//
//extension ContentType {
//
//    struct Filter: Codable {
//
//        enum Method: String, Codable {
//            case equals
//        }
//
//        let field: String
//        let method: Method
//        let value: String
//    }
//}
//
//extension ContentType {
//
//    struct Context: Codable {
//
//        struct Site: Codable {
//            let sort: String?
//            let order: Order?
//            let limit: Int?
//            let filter: Filter?
//        }
//
//        struct Local: Codable {
//            let references: String
//            let foreignKey: String
//            let sort: String?
//            let order: Order?
//            let limit: Int?
//        }
//
//        let site: [String: Site]?
//        let local: [String: Local]?
//    }
//}
