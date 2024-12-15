//
//  File.swift
//  toucan
//
//  Created by Tibor Bodecs on 2024. 10. 13..
//

import Foundation
import Logging

struct ContextStore {

    let sourceConfig: SourceConfig
    let contentTypes: [ContentType]
    let blockDirectives: [Block]
    let pageBundles: [PageBundle]

    let logger: Logger

    let fileManager = FileManager.default
    let htmlToCParser: HTMLToCParser
    let markdownToCParser: MarkdownToCParser

    private var contentContextCache: ContentContextCache

    init(
        sourceConfig: SourceConfig,
        contentTypes: [ContentType],
        pageBundles: [PageBundle],
        blockDirectives: [Block],
        logger: Logger
    ) {
        self.sourceConfig = sourceConfig
        self.contentTypes = contentTypes
        self.pageBundles = pageBundles
        self.contentContextCache = .init()
        self.blockDirectives = blockDirectives
        self.logger = logger

        self.htmlToCParser = .init(logger: logger)
        self.markdownToCParser = .init()
    }

    private func baseContext(
        for pageBundle: PageBundle
    ) -> [String: Any] {
        pageBundle.baseContext
    }

    private func properties(
        for pageBundle: PageBundle
    ) -> [String: Any] {
        var properties: [String: Any] = [:]
        for (key, _) in pageBundle.contentType.properties ?? [:] {
            let value = pageBundle.frontMatter[key]
            properties[key] = value
        }
        return properties
    }

    private func contentContext(
        for pageBundle: PageBundle
    ) -> [String: Any] {
        var contents = pageBundle.markdown.dropFrontMatter()
        let markdownRenderer = MarkdownRenderer(
            blockDirectives: blockDirectives,
            delegate: HTMLRendererDelegate(
                config: sourceConfig.config,
                pageBundle: pageBundle
            ),
            logger: logger
        )

        let pipelines = sourceConfig.config.transformers.pipelines
        let pipeline = pipelines[pageBundle.contentType.id]
        var shouldRenderMarkdown = true

        if let pipeline {
            if !pipeline.run.isEmpty {
                shouldRenderMarkdown = pipeline.isMarkdownResult
                let executor = PipelineExecutor(
                    pipeline: pipeline,
                    pageBundle: pageBundle,
                    sourceConfig: sourceConfig,
                    fileManager: fileManager,
                    logger: logger
                )
                do {
                    contents = try executor.execute()
                }
                catch {
                    logger.error("\(String(describing: error))")
                }
            }
            else {
                logger.warning("Empty transformer pipeline.")
            }
        }

        let tocElements: [TocElement]
        if shouldRenderMarkdown {
            tocElements = markdownToCParser.parse(from: contents) ?? []
            contents = markdownRenderer.renderHTML(markdown: contents)
        }
        else {
            tocElements = htmlToCParser.parse(from: contents) ?? []
        }
        return [
            "contents": contents,
            "readingTime": contents.readingTime(),
            "toc": tocElements.buildToCTree(),
        ]
    }

    private func relations(
        for pageBundle: PageBundle
    ) -> [String: [PageBundle]] {
        var result: [String: [PageBundle]] = [:]
        for (key, value) in pageBundle.contentType.relations ?? [:] {
            let refIds = pageBundle.referenceIdentifiers(
                for: key,
                join: value.join
            )

            let refs =
                pageBundles
                .filter { $0.contentType.id == value.references }
                .filter { item in
                    refIds.contains(item.contextAwareIdentifier)
                }
                .sorted(frontMatterKey: value.sort, order: value.order)
                .limited(value.limit)

            result[key] = refs
        }
        return result
    }

    // MARK: -

    /// can be resolved without joining any relations.
    private func standardContext(
        for pageBundle: PageBundle
    ) -> [String: Any] {
        let _baseContext = baseContext(for: pageBundle)
        let _contentContext = ensureContentContext(for: pageBundle)
        let _properties = properties(for: pageBundle)
        let _relations = relations(for: pageBundle)
            .mapValues { $0.map { standardContext(for: $0) } }

        let context =
            _baseContext
            .recursivelyMerged(with: _contentContext)
            .recursivelyMerged(with: _properties)
            .recursivelyMerged(with: _relations)

        return context
    }

    /// Ensures that the content context for the given page bundle is retrieved from cache or generated if not present.
    ///
    /// - Parameters:
    ///   - pageBundle: The bundle containing the page data for which the content context is being requested.
    /// - Returns:
    ///   A dictionary representing the content context for the specified page bundle.
    private func ensureContentContext(
        for pageBundle: PageBundle
    ) -> [String: Any] {
        if let context = contentContextCache.getItem(forKey: pageBundle.slug) {
            return context
        }

        let newContext = contentContext(for: pageBundle)
        contentContextCache.addItem(newContext, forKey: pageBundle.slug)

        return newContext
    }

    // MARK: -

    private func localContext(
        for pageBundle: PageBundle
    ) -> [String: [PageBundle]] {
        let id = pageBundle.contextAwareIdentifier
        var localContext: [String: [PageBundle]] = [:]
        let contentType = pageBundle.contentType

        for (key, value) in contentType.context?.local ?? [:] {
            if value.foreignKey.hasPrefix("$") {
                var command = String(value.foreignKey.dropFirst())
                var arguments: [String] = []
                if command.contains(".") {
                    let all = command.split(separator: ".")
                    command = String(all[0])
                    arguments = all.dropFirst().map(String.init)
                }

                let refs =
                    pageBundles
                    .filter { $0.contentType.id == value.references }
                    .sorted(frontMatterKey: value.sort, order: value.order)

                guard
                    let idx = refs.firstIndex(where: {
                        $0.slug == pageBundle.slug
                    })
                else {
                    continue
                }

                switch command {
                case "prev":
                    guard idx > 0 else {
                        continue
                    }
                    localContext[key] = [refs[idx - 1]]
                case "next":
                    guard idx < refs.count - 1 else {
                        continue
                    }
                    localContext[key] = [refs[idx + 1]]
                case "same":
                    guard let arg = arguments.first else {
                        continue
                    }
                    let ids = Set(pageBundle.referenceIdentifiers(for: arg))
                    localContext[key] =
                        refs.filter { pb in
                            if pb.slug == pageBundle.slug {
                                return false
                            }
                            let pbIds = Set(pb.referenceIdentifiers(for: arg))
                            return !ids.intersection(pbIds).isEmpty
                        }
                        .limited(value.limit)
                default:
                    continue
                }
            }
            else {
                localContext[key] =
                    pageBundles
                    .filter { $0.contentType.id == value.references }
                    .filter {
                        $0.referenceIdentifiers(
                            for: value.foreignKey
                        )
                        .contains(id)
                    }
                    .sorted(frontMatterKey: value.sort, order: value.order)
                    .limited(value.limit)
            }
        }
        return localContext
    }

    func fullContext(
        for pageBundle: PageBundle
    ) -> [String: Any] {

        let metadata: Logger.Metadata = [
            "type": "\(pageBundle.contentType.id)",
            "slug": "\(pageBundle.slug)",
        ]

        logger.trace("Generating context", metadata: metadata)

        let _standardContext = standardContext(for: pageBundle)
        let _localContext = localContext(for: pageBundle)
            .mapValues { $0.map { standardContext(for: $0) } }

        let context =
            _standardContext
            .recursivelyMerged(with: _localContext)

        return context
    }

    // MARK: -

    func getPageBundlesForSiteContext() -> [String: [PageBundle]] {
        var result: [String: [PageBundle]] = [:]
        let dateFormatter = DateFormatters.baseFormatter

        for contentType in contentTypes {
            for (key, value) in contentType.context?.site ?? [:] {
                result[key] =
                    pageBundles
                    .filter { $0.contentType.id == contentType.id }
                    .sorted(frontMatterKey: value.sort, order: value.order)
                    .filtered(value.filter, dateFormatter: dateFormatter)
                    .limited(value.limit)
            }
        }

        return result
    }
}
