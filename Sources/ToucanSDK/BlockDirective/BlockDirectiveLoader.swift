//
//  File.swift
//  toucan
//
//  Created by Tibor Bodecs on 19/07/2024.
//

import Foundation
import Logging

struct BlockDirectiveLoader {

    let source: Source

    let fileLoader: FileLoader
    let yamlParser: YamlParser

    /// The logger instance
    let logger: Logger

    func load() throws -> [Block] {

        let blocksUrl = source.currentThemeUrl
            .appendingPathComponent("blocks")
        let overrideBlocksUrl = source.currentThemeOverrideUrl
            .appendingPathComponent("blocks")

        let contents = try fileLoader.findContents(at: blocksUrl)
        let overrideContents = try fileLoader.findContents(
            at: overrideBlocksUrl
        )

        let blocks = try contents.map {
            try yamlParser.decode($0, as: Block.self)
        }
        let overrideBlocks = try overrideContents.map {
            try yamlParser.decode($0, as: Block.self)
        }

        var finalBlocks: [Block] = overrideBlocks
        for type in blocks {
            if !finalBlocks.contains(where: { $0.name == type.name }) {
                finalBlocks.append(type)
            }
        }

        logger.debug(
            "Available block directives: `\(finalBlocks.map(\.name).joined(separator: ", "))`."
        )

        return finalBlocks
    }
}
