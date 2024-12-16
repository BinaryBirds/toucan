//
//  File.swift
//
//
//  Created by Tibor Bodecs on 03/05/2024.
//

import Foundation
import FileManagerKit
import Logging

/// A static site generator.
public struct Toucan {

    // MARK: -

    let inputUrl: URL
    let outputUrl: URL
    let baseUrl: String?
    let seoChecks: Bool
    let logger: Logger

    /// Initialize a new instance.
    /// - Parameters:
    ///   - input: The input url as a path string.
    ///   - output: The output url as a path string.
    ///   - baseUrl: An optional baseUrl to override the config value.
    public init(
        input: String,
        output: String,
        baseUrl: String?,
        seoChecks: Bool,
        logger: Logger = .init(label: "toucan")
    ) {
        self.fileManager = FileManager.default

        let home = fileManager.homeDirectoryForCurrentUser.path

        func getSafeUrl(_ path: String, home: String) -> URL {
            .init(
                fileURLWithPath: path.replacingOccurrences(["~": home])
            )
            .standardized
        }

        self.inputUrl = getSafeUrl(input, home: home)
        self.outputUrl = getSafeUrl(output, home: home)
        self.baseUrl = baseUrl
        self.seoChecks = seoChecks
        self.logger = logger
    }

    // MARK: - file management

    let fileManager: FileManager

    // MARK: - directory management

    func resetDirectory(at url: URL) throws {
        if fileManager.exists(at: url) {
            try fileManager.delete(at: url)
        }
        try fileManager.createDirectory(at: url)
    }

    /// generates the static site
    public func generate() throws {
        let processId = UUID()
        let workDirUrl = fileManager
            .temporaryDirectory
            .appendingPathComponent("toucan")
            .appendingPathComponent(processId.uuidString)

        try resetDirectory(at: workDirUrl)

        logger.debug("Working at: `\(workDirUrl.absoluteString)`.")

        do {
            let loader = SourceBundleLoader(
                baseUrl: baseUrl,
                sourceUrl: inputUrl,
                yamlFileLoader: .yaml,
                fileManager: fileManager,
                frontMatterParser: .init(),
                logger: logger
            )
            let source = try loader.load()
            source.validate(dateFormatter: DateFormatters.baseFormatter)

            // theme assets
            try fileManager.copyRecursively(
                from: source.source.currentThemeAssetsUrl,
                to: workDirUrl
            )
            // theme override assets
            try fileManager.copyRecursively(
                from: source.source.currentThemeOverrideAssetsUrl,
                to: workDirUrl
            )
            // copy global site assets
            try fileManager.copyRecursively(
                from: source.source.assetsUrl,
                to: workDirUrl
            )

            // MARK: copy assets

            for pageBundle in source.pageBundles {
                let assetsUrl = pageBundle.url
                    .appendingPathComponent(pageBundle.config.assets.folder)

                guard
                    fileManager.directoryExists(at: assetsUrl),
                    !fileManager.listDirectory(at: assetsUrl).isEmpty
                else {
                    continue
                }

                let workDirUrl =
                    workDirUrl
                    .appendingPathComponent(pageBundle.config.assets.folder)
                    .appendingPathComponent(pageBundle.assetsLocation)

                try fileManager.copyRecursively(
                    from: assetsUrl,
                    to: workDirUrl
                )
            }

            let templateRenderer = try MustacheToHTMLRenderer(
                templatesUrl: source.source.currentThemeTemplatesUrl,
                overridesUrl: source
                    .source
                    .currentThemeOverrideTemplatesUrl,
                logger: logger
            )

            let redirectRenderer = RedirectRenderer(
                destinationUrl: workDirUrl,
                fileManager: .default,
                templateRenderer: templateRenderer,
                pageBundles: source.pageBundles
            )
            try redirectRenderer.render()

            let sitemapRenderer = SitemapRenderer(
                destinationUrl: workDirUrl,
                fileManager: .default,
                templateRenderer: templateRenderer,
                pageBundles: source.sitemapPageBundles()
            )
            try sitemapRenderer.render()

            let rssRenderer = RSSRenderer(
                source: source.source,
                destinationUrl: workDirUrl,
                fileManager: .default,
                templateRenderer: templateRenderer,
                pageBundles: source.rssPageBundles()
            )
            try rssRenderer.render()

            let htmlRenderer = try HTMLRenderer(
                sourceBundle: source,
                destinationUrl: workDirUrl,
                templateRenderer: templateRenderer,
                seoChecks: seoChecks,
                logger: logger
            )

            try htmlRenderer.render()

            let apiRenderer = try APIRenderer(
                source: source,
                destinationUrl: workDirUrl,
                logger: logger
            )
            try apiRenderer.render()

            try resetDirectory(at: outputUrl)
            try fileManager.copyRecursively(from: workDirUrl, to: outputUrl)

            try? fileManager.removeItem(at: workDirUrl)
        }
        catch {
            try? fileManager.removeItem(at: workDirUrl)
            throw error
        }
    }
}
