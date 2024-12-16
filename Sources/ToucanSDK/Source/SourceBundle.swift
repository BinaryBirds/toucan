//
//  File.swift
//
//
//  Created by Tibor Bodecs on 13/06/2024.
//

import Foundation
import Logging

struct SourceBundle {

    let source: Source
    let siteBundle: SiteBundle
    let contentTypes: [NewContentType]
    let blockDirectives: [Block]
    let pageBundles: [PageBundle]
    let logger: Logger

    func validate(dateFormatter: DateFormatter) {
        validateSlugs()
        validateFrontMatters(dateFormatter: dateFormatter)
    }

    // MARK: -

    func validateSlugs() {
        let slugs = pageBundles.map(\.slug)
        let uniqueSlugs = Set(slugs)
        if slugs.count != uniqueSlugs.count {
            logger.error("Invalid slugs")

            var seenSlugs = Set<String>()
            var duplicateSlugs = Set<String>()
            for element in slugs {
                if seenSlugs.contains(element) {
                    duplicateSlugs.insert(element)
                }
                else {
                    seenSlugs.insert(element)
                }
            }

            for element in duplicateSlugs {
                logger.error("Duplicate slug: \(element)")
            }
        }
    }

    func validateFrontMatters(dateFormatter: DateFormatter) {
        for pageBundle in pageBundles {
            validateFrontMatter(
                pageBundle.frontMatter,
                for: pageBundle.contentType,
                at: pageBundle.slug,
                dateFormatter: dateFormatter
            )
        }
    }

    // MARK: -

    func validateFrontMatter(
        _ frontMatter: [String: Any],
        for contentType: NewContentType,
        at slug: String,
        dateFormatter: DateFormatter
    ) {
        let metadata: Logger.Metadata = [
            "contentType": "\(contentType.id)",
            "slug": "\(slug)",
        ]

        // properties
        for property in contentType.properties ?? [:] {
            let hasValue = frontMatter[property.key] != nil
//            let hasDefaultValue = property.value.defaultValue != nil

//            if !hasValue && !hasDefaultValue {
//                logger.warning(
//                    "Missing content type property: `\(property.key)`",
//                    metadata: metadata
//                )
//            }
        }

        // relations
//        for relation in contentType.relations ?? [:] {
//            if frontMatter[relation.key] == nil {
//                logger.warning(
//                    "Missing content type relation: `\(relation.key)`",
//                    metadata: metadata
//                )
//            }
//        }
    }

    // MARK: -

    func pageBundles(by contentType: String) -> [PageBundle] {
        pageBundles.filter { $0.contentType.id == contentType }
    }

    func rssPageBundles() -> [PageBundle] {
        contentTypes
//            .filter { $0.id != ContentType.pagination.id }
//            .filter { $0.rss == true }
            .flatMap {
                pageBundles(by: $0.id)
            }
            .sorted { $0.publication > $1.publication }
    }

    func sitemapPageBundles() -> [PageBundle] {
        pageBundles
//            .filter { $0.contentType.id != ContentType.pagination.id }
            .filter { $0.id != source.config.contents.notFound.id }
            .sorted { $0.publication > $1.publication }
    }
}
