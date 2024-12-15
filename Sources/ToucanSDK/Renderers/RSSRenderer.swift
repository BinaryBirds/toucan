//
//  File.swift
//  toucan
//
//  Created by Tibor Bodecs on 2024. 10. 13..
//

import Foundation

struct RSSRenderer {

    let sourceConfig: SourceConfig
    let destinationUrl: URL
    let fileManager: FileManager
    let templateRenderer: MustacheToHTMLRenderer
    let pageBundles: [PageBundle]

    func render() throws {
        guard !pageBundles.isEmpty else {
            return
        }

        let items: [RSSContext.Item] =
            pageBundles
            .map { item in
                .init(
                    permalink: item.permalink,
                    title: item.title,
                    description: item.description,
                    publicationDate: item.date.rss
                )
            }

        let rssDateFormatter = DateFormatters.rss

        let publicationDate =
            items.first?.publicationDate
            ?? rssDateFormatter.string(from: .init())

#warning("FIXME")
        let context = RSSContext(
            title: "sourceConfig.site.title",
            description: "sourceConfig.site.description",
            baseUrl: "sourceConfig.site.baseUrl",
            language: "sourceConfig.site.language",
            lastBuildDate: rssDateFormatter.string(from: .init()),
            publicationDate: publicationDate,
            items: items
        )
        try templateRenderer.render(
            template: "rss",
            with: context,
            to:
                destinationUrl
                .appendingPathComponent(sourceConfig.config.contents.rss.output)
        )
    }
}
