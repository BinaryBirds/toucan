//
//  File.swift
//
//
//  Created by Tibor Bodecs on 27/06/2024.
//

import Foundation
import Logging

struct SourceLoader {

    let baseUrl: String?
    let sourceUrl: URL
    let yamlFileLoader: FileLoader
    let fileManager: FileManager
    let frontMatterParser: FrontMatterParser
    let logger: Logger

    /// load the configuration & the contents of the site source
    func load() throws -> Source {

        let configLoader = ConfigLoader(
            sourceUrl: sourceUrl,
            fileLoader: yamlFileLoader,
            logger: logger
        )
        let config = try configLoader.load()

        let siteLoader = SiteBundleLoader(
            sourceUrl: sourceUrl,
            config: config,
            fileLoader: .yaml,
            baseUrl: baseUrl,
            logger: logger
        )
        let siteBundle = try siteLoader.load()

        let sourceConfig = SourceConfig(
            sourceUrl: sourceUrl,
            config: config,
            siteBundle: siteBundle
        )

        logger.trace(
            "Themes location url: `\(sourceConfig.themesUrl.absoluteString)`"
        )
        logger.trace(
            "Current theme url: `\(sourceConfig.currentThemeUrl.absoluteString)`"
        )
        logger.trace(
            "Current theme assets url: `\(sourceConfig.currentThemeAssetsUrl.absoluteString)`"
        )
        logger.trace(
            "Current theme templates url: `\(sourceConfig.currentThemeTemplatesUrl.absoluteString)`"
        )
        logger.trace(
            "Current theme types url: `\(sourceConfig.currentThemeTypesUrl.absoluteString)`"
        )

        logger.trace(
            "Theme override url: `\(sourceConfig.currentThemeOverrideUrl.absoluteString)`"
        )
        logger.trace(
            "Theme override assets url: `\(sourceConfig.currentThemeOverrideAssetsUrl.absoluteString)`"
        )
        logger.trace(
            "Theme override templates url: `\(sourceConfig.currentThemeOverrideTemplatesUrl.absoluteString)`"
        )
        logger.trace(
            "Theme override types url: `\(sourceConfig.currentThemeOverrideTypesUrl.absoluteString)`"
        )

        let contentTypeLoader = ContentTypeLoader(
            sourceConfig: sourceConfig,
            fileLoader: .yaml,
            yamlParser: .init(),
            logger: logger
        )

        let contentTypes = try contentTypeLoader.load()

        let blockDirectiveLoader = BlockDirectiveLoader(
            sourceConfig: sourceConfig,
            fileLoader: .yaml,
            yamlParser: .init(),
            logger: logger
        )

        let blockDirectives = try blockDirectiveLoader.load()

        let pageBundleLoader = PageBundleLoader(
            sourceConfig: sourceConfig,
            contentTypes: contentTypes,
            fileManager: fileManager,
            frontMatterParser: frontMatterParser,
            logger: logger
        )
        let pageBundles = try pageBundleLoader.load()

        return .init(
            sourceConfig: sourceConfig,
            contentTypes: contentTypes,
            blockDirectives: blockDirectives,
            pageBundles: pageBundles,
            logger: logger
        )
    }
}
