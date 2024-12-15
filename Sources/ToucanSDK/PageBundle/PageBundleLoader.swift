//
//  File.swift
//
//
//  Created by Tibor Bodecs on 27/06/2024.
//

import Foundation
import FileManagerKit
import Logging

public struct PageBundleLoader {

    /// An enumeration representing possible errors that can occur while loading the content.
    public enum Error: Swift.Error {
        //        case indexFileNotExists
        /// Indicates an error related to a content.
        case pageBundle(Swift.Error)
    }

    let sourceConfig: SourceConfig
    let contentTypes: [ContentType]

    /// The file manager used for file operations.
    let fileManager: FileManager
    /// The front matter parser used for parsing markdown files.
    let frontMatterParser: FrontMatterParser

    let logger: Logger

    /// The current date.
    let now: Date = .init()

    private let indexName = "index"
    private let mdExtensions = ["md", "markdown"]
    private let yamlExtensions = ["yaml", "yml"]

    private var extensions: [String] {
        mdExtensions + yamlExtensions
    }

    /// Loads all the page bundles.
    func load() throws -> [PageBundle] {
        try PageBundleLocator(
            fileManager: fileManager,
            contentsUrl: sourceConfig.contentsUrl
        )
        .locate()
        .compactMap { try loadPageBundle(at: $0) }
        .sorted { $0.slug < $1.slug }
    }

    // MARK: - loading

    func loadPageBundle(
        at location: PageBundleLocation
    ) throws -> PageBundle? {
        let dirUrl = sourceConfig.contentsUrl.appendingPathComponent(
            location.path
        )

        let id = location.path
        let metadata: Logger.Metadata = [
            "id": "\(id)"
        ]

        logger.debug(
            "Loading page bundle.",
            metadata: metadata
        )

        guard fileManager.directoryExists(at: dirUrl) else {
            logger.debug(
                "Page bundle directory does not exists.",
                metadata: metadata
            )
            return nil
        }
        do {
            let lastModification = try getLastModificationDate(at: dirUrl)
            let rawMarkdown = try getRawMarkdown(at: dirUrl)
            let markdown = rawMarkdown.dropFrontMatter()
            let frontMatter = try getFrontMatter(
                id: indexName,
                dirUrl: dirUrl,
                rawMarkdown: rawMarkdown
            )

            let config = PageBundle.Config(frontMatter)

            /// filter out drafts
            if config.draft {
                logger.debug("Page bundle is a draft.", metadata: metadata)
                return nil
            }

            // check for publication date
            let formatter = DateFormatters.baseFormatter
            #warning("FIXME")
            //            formatter.dateFormat = sourceConfig.config.contents.dateFormat
            var publicationDate = now
            if let pub = config.publication,
                let date = formatter.date(from: pub)
            {
                publicationDate = date
            }

            if publicationDate > now {
                logger.debug(
                    "Page bundle is not published yet.",
                    metadata: metadata
                )
                return nil
            }

            // check for expiration date
            if let exp = config.expiration,
                let expiration = formatter.date(from: exp),
                expiration < now
            {
                logger.debug(
                    "Page bundle is already expired.",
                    metadata: metadata
                )
                return nil
            }

            // check for valid content type
            let contentType = getContentType(
                for: location,
                explicitType: config.type
            )
            guard let contentType else {
                logger.debug(
                    "Page bundle has invalid content type.",
                    metadata: metadata
                )
                return nil
            }

            // create safe slug, set empty slug for home page if needed
            var slug = (config.slug ?? location.slug).safeSlug(prefix: nil)
            if id == sourceConfig.config.contents.home.id {
                slug = ""
            }

            let assetsPath = config.assets.folder
            let assetsUrl = dirUrl.appendingPathComponent(assetsPath)
            let assets = fileManager.recursivelyListDirectory(at: assetsUrl)
                .filter { !$0.hasPrefix(".") }

            let properties = config.userDefined.filter {
                contentType.propertyKeys.contains($0.key)
            }
            let relations = config.userDefined.filter {
                contentType.relationKeys.contains($0.key)
            }

            logger.debug(
                "Page bundle is loaded.",
                metadata: metadata
            )

            #warning("FIXME")
            let pageBundle = PageBundle(
                id: id,
                url: dirUrl,
                baseUrl: "sourceConfig.site.baseUrl",
                slug: slug,
                permalink: slug.permalink(
                    baseUrl: "sourceConfig.site.baseUrl"
                ),
                title: config.title.nilToEmpty,
                description: config.description.nilToEmpty,
                date: convert(date: publicationDate),
                contentType: contentType,
                publication: publicationDate,
                lastModification: lastModification,
                config: config,
                frontMatter: frontMatter,
                properties: properties,
                relations: relations,
                markdown: markdown,
                assets: assets
            )
            return pageBundle
        }
        catch {
            throw Error.pageBundle(error)
        }
    }
}

extension PageBundleLoader {

    func convert(
        date: Date
    ) -> PageBundle.DateValue {
        let html = DateFormatters.baseFormatter
        #warning("FIXME")
        //        html.dateFormat = sourceConfig.site.dateFormat
        let rss = DateFormatters.rss
        let sitemap = DateFormatters.sitemap

        return .init(
            html: html.string(from: date),
            rss: rss.string(from: date),
            sitemap: sitemap.string(from: date)
        )
    }

    func getContentType(
        for location: PageBundleLocation,
        explicitType: String?
    ) -> ContentType? {
        var assumedType: String?
        for contentType in contentTypes {
            guard
                let locPrefix = contentType.location, !locPrefix.isEmpty
            else {
                continue
            }
            if location.path.hasPrefix(locPrefix) {
                assumedType = contentType.id
            }
        }

        if let explicitType {
            assumedType = explicitType
        }
        let type = assumedType ?? ContentType.default.id
        return contentTypes.first { $0.id == type }
    }

}

// MARK: - helpers to get page bundle contents

extension PageBundleLoader {

    func getLastModificationDate(
        at url: URL
    ) throws -> Date {
        var date: Date?
        for ext in extensions {
            let fileUrl = url.appendingPathComponent("\(indexName).\(ext)")
            guard fileManager.fileExists(at: fileUrl) else {
                continue
            }
            let fileDate = try fileManager.modificationDate(at: fileUrl)
            if date == nil || date! < fileDate {
                date = fileDate
            }
        }
        precondition(date != nil, "Last modification date is nil.")
        return date!
    }

    func getRawMarkdown(
        at url: URL
    ) throws -> String {
        for ext in mdExtensions {
            let fileUrl = url.appendingPathComponent("\(indexName).\(ext)")
            if fileManager.fileExists(at: fileUrl) {
                return try String(contentsOf: fileUrl, encoding: .utf8)
            }
        }
        return ""
    }

    func getFrontMatter(
        id: String,
        dirUrl: URL,
        rawMarkdown: String
    ) throws -> [String: Any] {
        /// use front matter from the markdown file
        let frontMatter = try frontMatterParser.parse(markdown: rawMarkdown)

        /// load additional yaml files for meta data overrides
        let url = dirUrl.appendingPathComponent(id)
        do {
            let overrides = try FileLoader.yaml
                .loadContents(at: url)
                .decodeYaml()
            return frontMatter.recursivelyMerged(with: overrides)
        }
        catch FileLoader.Error.missing {
            return frontMatter
        }
    }
}
