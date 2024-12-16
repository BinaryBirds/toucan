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

    let sourceBundle: SourceBundle
    let destinationUrl: URL
    let templateRenderer: MustacheToHTMLRenderer
    let logger: Logger

    let fileManager: FileManager = .default
    let currentYear: Int

    let contextStore: ContextStore
    let seoChecks: Bool

    init(
        sourceBundle: SourceBundle,
        destinationUrl: URL,
        templateRenderer: MustacheToHTMLRenderer,
        seoChecks: Bool,
        logger: Logger
    ) throws {
        self.sourceBundle = sourceBundle
        self.destinationUrl = destinationUrl
        self.templateRenderer = templateRenderer
        self.seoChecks = seoChecks
        self.logger = logger

        let calendar = Calendar(identifier: .gregorian)
        self.currentYear = calendar.component(.year, from: .init())

        self.contextStore = .init(
            source: sourceBundle.source,
            contentTypes: sourceBundle.contentTypes,
            pageBundles: sourceBundle.pageBundles,
            blockDirectives: sourceBundle.blockDirectives,
            logger: logger
        )
    }

    // MARK: - page bundle rendering

    func renderHTML(
        pageBundle: PageBundle,
        globalContext: [String: [[String: Any]]],
        paginationContext: [String: [Context.Pagination.Link]],
        paginationData: [String: [PageBundle]]
    ) throws {
        
        

//        var fileUrl =
//            destinationUrl
//            .appendingPathComponent(pageBundle.slug)
//            .appendingPathComponent(Files.index)
//
//        var template =
//            pageBundle.config.template
//            ?? pageBundle.contentType.template
//
//        if pageBundle.id == source.source.config.contents.home.id {
//            fileUrl =
//                destinationUrl
//                .appendingPathComponent(Files.index)
//            template =
//                pageBundle.config.template
//                ?? source.source.config.contents.home.template
//        }
//
//        if pageBundle.id == source.source.config.contents.notFound.id {
//            fileUrl =
//                destinationUrl
//                .appendingPathComponent(Files.notFound)
//            template =
//                pageBundle.config.template
//                ?? source.source.config.contents.notFound.template
//        }
//
//        if let output = pageBundle.config.output {
//            fileUrl =
//                destinationUrl
//                .appendingPathComponent(output)
//        }
//
//        try fileManager.createParentFolderIfNeeded(
//            for: fileUrl
//        )
//
//        let context = HTML(
//            baseUrl: source.source.config.site.baseUrl,
//            siteBundle: source.source.siteBundle.userDefined,
//            siteContext: globalContext,
//            page: contextStore.fullContext(for: pageBundle),
//            userDefined: pageBundle.config.userDefined,
//            pagination: .init(
//                links: paginationContext,
//                data: paginationData.mapValues {
//                    $0.map {
//                        contextStore.fullContext(for: $0)
//                    }
//                }
//            ),
//            year: currentYear
//        )
//        .context
//
//        let metadata: Logger.Metadata = [
//            "type": "\(pageBundle.contentType.id)",
//            "slug": "\(pageBundle.slug)",
//        ]
//
//        guard
//            let html = try templateRenderer.render(
//                template: template ?? "pages.default",
//                with: context
//            )
//        else {
//            logger.error("Missing HTML contents.", metadata: metadata)
//            return
//        }
//
//        if seoChecks {
//            let seoValidator = SEOValidator(logger: logger)
//            seoValidator.validate(html: html, using: pageBundle)
//        }
//
//        try html.write(to: fileUrl, atomically: true, encoding: .utf8)
    }
    
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

    // MARK: - render related methods

    func render() throws {
//        print("----------------------------------------------------")
        
        // put together global context
        var globalContext: [String: [String: Any]] = [:]
        for contentType in sourceBundle.contentTypes {
            guard let html = contentType.html else { continue }
            guard let context = html.globalContext else { continue }

            globalContext[contentType.id] = [:]
            
            for (key, value) in context {
                globalContext[contentType.id]?[key] = "..."
//                print(value.query)
//                print(value.context)
            }

//            print("----------")
        }
//        print(globalContext)
        
        // render paginated content type + page bundle
        for contentType in sourceBundle.contentTypes {
            print(contentType.id)
            let pageBundles = sourceBundle.pageBundles(by: contentType.id)
//                print(pageBundles.map { $0.slug })
//                    .sorted(
//                        frontMatterKey: pagination.sort,
//                        order: pagination.order
//                    )

            if
                let html = contentType.html,
                let pagination = html.contentType,
                let query = pagination.query,
                let output = pagination.output,
                let template = pagination.template,
                let context = pagination.context
            {
                let limit = query.limit ?? 20
                let pages = pageBundles.chunks(ofCount: limit)
                let total = pages.count

//                print(limit)
//                print(output)
//                print(template)
//                for (index, current) in pages.enumerated() {
//                    let page = Array(current).map { $0.slug }
//                    print(index, page)
//                }
//                
//                print("-----!!!---------")
//                for (key, value) in context {
//                    print(key, value)
//                }
//                print("------!!!--------")
//                
//                print("--------------")
//                print(limit, total)
//                print("--------------")
            }

            for pageBundle in pageBundles {
                print(pageBundle.slug)
                print("-------------")
                
                var finalContext: [String: Any] = [:]
                
                if
                    let html = contentType.html,
                    let page = html.pageBundle,
                    let context = page.context
                {
                    print(pageBundle.slug)
                    for (key, contextItem) in context {
                        if let property = contextItem.property {
                            let value = pageBundle.frontMatter[property]
                            // TODO: apply format
//                            if let formatter = contextItem.formatter {
//                                print(formatter)
//                            }
                            finalContext[key] = value
                        }
                        if let relation = contextItem.relation {
                            let refIds = pageBundle.referenceIdentifiers(
                                for: key,
                                join: relation.join
                            )
                            print(relation.references)
                            print(refIds)
                            
//                            print(relation.order)
//                            print(relation.join)
//                            print(relation.sort)
                        }
                    }
                }

                print(finalContext)
            }
        }
    }
}
