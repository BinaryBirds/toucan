//
//  File.swift
//  toucan
//
//  Created by Tibor Bodecs on 19/07/2024.
//

import Foundation
import Logging

/// A struct responsible for loading and managing content types.
struct ContentTypeLoader {

    let source: Source

    let fileLoader: FileLoader
    let yamlParser: YamlParser

    /// The logger instance
    let logger: Logger

    /// Loads and returns an array of content types.
    ///
    /// - Throws: An error if the content types could not be loaded.
    /// - Returns: An array of `ContentType` objects.
    func load() throws -> [NewContentType] {

        let typesUrl = source.currentThemeTypesUrl
        let overrideTypesUrl = source.currentThemeOverrideTypesUrl
        let contents = try fileLoader.findContents(at: typesUrl)
        let overrideContents = try fileLoader.findContents(at: overrideTypesUrl)

        
        
        let types = try contents.map {
            try yamlParser.decode($0, as: NewContentType.self)
        }
        let overrideTypes = try overrideContents.compactMap {
            try yamlParser.decode($0, as: NewContentType.self)
        }

        var finalTypes: [NewContentType] = overrideTypes
        for type in types {
            if !finalTypes.contains(where: { $0.id == type.id }) {
                finalTypes.append(type)
            }
        }

        // Adding the default content type if not present
//        if !finalTypes.contains(where: { $0.id == ContentType.default.id }) {
//            finalTypes.append(.default)
//        }

//        logger.debug(
//            "Available content types: `\(finalTypes.map(\.id).joined(separator: ", "))`."
//        )

        return finalTypes
    }
}
