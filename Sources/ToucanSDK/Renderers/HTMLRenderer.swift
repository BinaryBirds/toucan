//
//  File.swift
//
//
//  Created by Tibor Bodecs on 21/06/2024.
//

import Foundation
import Logging
import Algorithms

/// Responsible to build renderable files using the site context & templates.
struct HTMLRenderer {

    public enum Files {
        static let index = "index.html"
        static let notFound = "404.html"
    }

    let source: Source
    let destinationUrl: URL
    let templateRenderer: MustacheToHTMLRenderer
    let logger: Logger

    let fileManager: FileManager = .default
    let currentYear: Int

    let contextStore: ContextStore
    let seoChecks: Bool

    init(
        source: Source,
        destinationUrl: URL,
        templateRenderer: MustacheToHTMLRenderer,
        seoChecks: Bool,
        logger: Logger
    ) throws {
        self.source = source
        self.destinationUrl = destinationUrl
        self.templateRenderer = templateRenderer
        self.seoChecks = seoChecks
        self.logger = logger

        let calendar = Calendar(identifier: .gregorian)
        self.currentYear = calendar.component(.year, from: .init())

        self.contextStore = .init(
            sourceConfig: source.sourceConfig,
            contentTypes: source.contentTypes,
            pageBundles: source.pageBundles,
            blockDirectives: source.blockDirectives,
            logger: logger
        )
    }

    // TODO: optimize & merge with data?
    func paginationContext(
        for pageBundle: PageBundle
    ) -> [String: [Context.Pagination.Link]] {
        var result: [String: [Context.Pagination.Link]] = [:]
        for contentType in source.contentTypes {
            guard let pagination = contentType.pagination else { continue }
            let paginationBundle = source.pageBundles.first { pageBundle in
                guard pageBundle.contentType.id == ContentType.pagination.id
                else {
                    return false
                }
                guard pageBundle.id == pagination.bundle else { return false }
                guard pageBundle.slug.contains("{{number}}") else {
                    return false
                }
                return true
            }
            guard let paginationBundle else {
                continue
            }

            let pageBundles = source.pageBundles(by: contentType.id)
                .sorted(
                    frontMatterKey: pagination.sort,
                    order: pagination.order
                )

            let limit = pagination.limit
            let pages = pageBundles.chunks(ofCount: limit)
            let total = pages.count

            var ctx: [Context.Pagination.Link] = []
            for (index, _) in pages.enumerated() {
                let number = index + 1
                let slug = paginationBundle.slug.replacingOccurrences([
                    "{{number}}": String(number),
                    "{{total}}": String(total),
                ])
                let permalink = slug.permalink(
                    baseUrl: source.sourceConfig.config.site.baseUrl
                )
                let isCurrent = pageBundle.slug == slug
                ctx.append(
                    .init(
                        number: number,
                        total: total,
                        slug: slug,
                        permalink: permalink,
                        isCurrent: isCurrent
                    )
                )
            }
            result[contentType.id] = ctx
        }
        return result
    }

    // MARK: - page bundle rendering

    func renderHTML(
        pageBundle: PageBundle,
        globalContext: [String: [[String: Any]]],
        paginationContext: [String: [Context.Pagination.Link]],
        paginationData: [String: [PageBundle]]
    ) throws {

        var fileUrl =
            destinationUrl
            .appendingPathComponent(pageBundle.slug)
            .appendingPathComponent(Files.index)

        var template =
            pageBundle.config.template
            ?? pageBundle.contentType.template

        if pageBundle.id == source.sourceConfig.config.contents.home.id {
            fileUrl =
                destinationUrl
                .appendingPathComponent(Files.index)
            template =
                pageBundle.config.template
                ?? source.sourceConfig.config.contents.home.template
        }

        if pageBundle.id == source.sourceConfig.config.contents.notFound.id {
            fileUrl =
                destinationUrl
                .appendingPathComponent(Files.notFound)
            template =
                pageBundle.config.template
                ?? source.sourceConfig.config.contents.notFound.template
        }

        if let output = pageBundle.config.output {
            fileUrl =
                destinationUrl
                .appendingPathComponent(output)
        }

        try fileManager.createParentFolderIfNeeded(
            for: fileUrl
        )

        let context = HTML(
            baseUrl: source.sourceConfig.config.site.baseUrl,
            siteBundle: source.sourceConfig.siteBundle.userDefined,
            siteContext: globalContext,
            page: contextStore.fullContext(for: pageBundle),
            userDefined: pageBundle.config.userDefined,
            pagination: .init(
                links: paginationContext,
                data: paginationData.mapValues {
                    $0.map {
                        contextStore.fullContext(for: $0)
                    }
                }
            ),
            year: currentYear
        )
        .context

        let metadata: Logger.Metadata = [
            "type": "\(pageBundle.contentType.id)",
            "slug": "\(pageBundle.slug)",
        ]

        guard
            let html = try templateRenderer.render(
                template: template ?? "pages.default",
                with: context
            )
        else {
            logger.error("Missing HTML contents.", metadata: metadata)
            return
        }

        if seoChecks {
            let seoValidator = SEOValidator(logger: logger)
            seoValidator.validate(html: html, using: pageBundle)
        }

        try html.write(to: fileUrl, atomically: true, encoding: .utf8)
    }

    // MARK: - render related methods

    func render() throws {
        let globalContext = contextStore.getPageBundlesForSiteContext()

        let siteContext = globalContext.mapValues {
            $0.map {
                contextStore.fullContext(for: $0)
            }
        }

        for pageBundle in source.pageBundles {
            guard pageBundle.contentType.id != ContentType.pagination.id else {
                continue
            }

            try renderHTML(
                pageBundle: pageBundle,
                globalContext: siteContext,
                paginationContext: paginationContext(for: pageBundle),
                paginationData: [:]
            )
        }

        for contentType in source.contentTypes {
            guard let pagination = contentType.pagination else { continue }

            for pageBundle in source.pageBundles {

                guard pageBundle.contentType.id == ContentType.pagination.id
                else {
                    continue
                }
                guard pageBundle.id == pagination.bundle else { continue }
                guard pageBundle.slug.contains("{{number}}") else {
                    continue
                }

                let pageBundles = source.pageBundles(by: contentType.id)
                    .sorted(
                        frontMatterKey: pagination.sort,
                        order: pagination.order
                    )

                let limit = pagination.limit
                let pages = pageBundles.chunks(ofCount: limit)
                let total = pages.count

                func replace(
                    in value: String,
                    number: Int,
                    total: Int
                ) -> String {
                    value.replacingOccurrences([
                        "{{number}}": String(number),
                        "{{total}}": String(total),
                    ])
                }

                for (index, current) in pages.enumerated() {
                    let number = index + 1
                    let finalSlug = replace(
                        in: pageBundle.slug,
                        number: number,
                        total: total
                    )
                    let finalTitle = replace(
                        in: pageBundle.title,
                        number: number,
                        total: total
                    )
                    let finalDescription = replace(
                        in: pageBundle.description,
                        number: number,
                        total: total
                    )
                    let finalMarkdown = replace(
                        in: pageBundle.markdown,
                        number: number,
                        total: total
                    )

                    let finalBundle = PageBundle(
                        id: pageBundle.id,
                        url: pageBundle.url,
                        baseUrl: source.sourceConfig.config.site.baseUrl,
                        slug: finalSlug,
                        permalink: finalSlug.permalink(
                            baseUrl: source.sourceConfig.config.site.baseUrl
                        ),
                        title: finalTitle,
                        description: finalDescription,
                        date: pageBundle.date,
                        contentType: pageBundle.contentType,
                        publication: pageBundle.publication,
                        lastModification: pageBundle.lastModification,
                        config: pageBundle.config,
                        frontMatter: pageBundle.frontMatter,
                        properties: pageBundle.properties,
                        relations: pageBundle.relations,
                        markdown: finalMarkdown,
                        assets: pageBundle.assets
                    )

                    try renderHTML(
                        pageBundle: finalBundle,
                        globalContext: siteContext,
                        paginationContext: paginationContext(for: finalBundle),
                        paginationData: [contentType.id: Array(current)]
                    )
                }
            }
        }
    }
}
