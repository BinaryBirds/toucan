//
//  File.swift
//
//
//  Created by Tibor Bodecs on 27/06/2024.
//

import Foundation
import Logging

struct SourceBundleLoader {

    let baseUrl: String?
    let sourceUrl: URL
    let yamlFileLoader: FileLoader
    let fileManager: FileManager
    let frontMatterParser: FrontMatterParser
    let logger: Logger

    /// load the configuration & the contents of the site source
    func load() throws -> SourceBundle {

        let configLoader = ConfigLoader(
            sourceUrl: sourceUrl,
            fileLoader: yamlFileLoader,
            logger: logger
        )
        let config = try configLoader.load()

        let source = Source(
            url: sourceUrl,
            config: config
        )
        
        let siteBundleLoader = SiteBundleLoader(
            source: source,
            fileLoader: .yaml,
            baseUrl: baseUrl,
            logger: logger
        )
        let siteBundle = try siteBundleLoader.load()

        logger.trace(
            "Themes location url: `\(source.themesUrl.absoluteString)`"
        )
        logger.trace(
            "Current theme url: `\(source.currentThemeUrl.absoluteString)`"
        )
        logger.trace(
            "Current theme assets url: `\(source.currentThemeAssetsUrl.absoluteString)`"
        )
        logger.trace(
            "Current theme templates url: `\(source.currentThemeTemplatesUrl.absoluteString)`"
        )
        logger.trace(
            "Current theme types url: `\(source.currentThemeTypesUrl.absoluteString)`"
        )

        logger.trace(
            "Theme override url: `\(source.currentThemeOverrideUrl.absoluteString)`"
        )
        logger.trace(
            "Theme override assets url: `\(source.currentThemeOverrideAssetsUrl.absoluteString)`"
        )
        logger.trace(
            "Theme override templates url: `\(source.currentThemeOverrideTemplatesUrl.absoluteString)`"
        )
        logger.trace(
            "Theme override types url: `\(source.currentThemeOverrideTypesUrl.absoluteString)`"
        )

        let contentTypeLoader = ContentTypeLoader(
            source: source,
            fileLoader: .yaml,
            yamlParser: .init(),
            logger: logger
        )

        let contentTypes = try contentTypeLoader.load()

        let blockDirectiveLoader = BlockDirectiveLoader(
            source: source,
            fileLoader: .yaml,
            yamlParser: .init(),
            logger: logger
        )

        let blockDirectives = try blockDirectiveLoader.load()

        let pageBundleLoader = PageBundleLoader(
            source: source,
            contentTypes: contentTypes,
            fileManager: fileManager,
            frontMatterParser: frontMatterParser,
            logger: logger
        )
        let pageBundles = try pageBundleLoader.load()

        return .init(
            source: source,
            siteBundle: siteBundle,
            contentTypes: contentTypes,
            blockDirectives: blockDirectives,
            pageBundles: pageBundles,
            logger: logger
        )
    }
}

