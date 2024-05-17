//
//  File.swift
//
//
//  Created by Tibor Bodecs on 10/05/2024.
//

import Foundation
import Mustache

extension String {

    func minifyHTML() -> String {
        self
        //        components(separatedBy: .newlines)
        //            .map { $0.trimmingCharacters(in: .whitespaces) }
        //            .joined()
    }
}

extension Site {

    func getContext() -> SiteContext {
        .init(
            baseUrl: baseUrl,
            title: title,
            language: language
        )
    }
}

extension Post {

    func getContext(
        site: Site,
        formatter: DateFormatter
    ) -> PostContext {
        .init(
            permalink: site.permalink("posts/" + slug),
            title: meta.title,
            exceprt: meta.description,
            date: formatter.string(from: publication),
            figure: .init(
                src: meta.imageUrl ?? "",
                darkSrc: nil,
                alt: meta.title,
                title: meta.title
            )
        )
    }
}

extension Author {

    func getContext(
        site: Site
    ) -> AuthorContext {
        .init(
            permalink: site.permalink("authors/" + slug),
            title: meta.title,
            excerpt: meta.description,
            imageUrl: meta.imageUrl
        )
    }
}

extension Tag {

    func getContext(
        site: Site
    ) -> TagContext {
        .init(
            permalink: site.permalink("tags/" + slug),
            title: meta.title,
            excerpt: meta.description,
            imageUrl: meta.imageUrl
        )
    }
}

struct TemplateLibrary {

    enum Error: Swift.Error {
        case missingTemplate(String)
    }

    private let site: Site
    private let library: MustacheLibrary
    private let ids: [String]

    init(
        site: Site,
        templatesUrl: URL
    ) throws {
        let ext = "mustache"
        var templates: [String: MustacheTemplate] = [:]

        if let dirContents = FileManager.default.enumerator(
            at: templatesUrl,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) {
            for case let url as URL in dirContents
            where url.pathExtension == ext {
                var relativePathComponents = url.pathComponents.dropFirst(
                    templatesUrl.pathComponents.count
                )
                let name = String(
                    relativePathComponents.removeLast()
                        .dropLast(".\(ext)".count)
                )
                relativePathComponents.append(name)
                let id = relativePathComponents.joined(separator: ".")
                templates[id] = try MustacheTemplate(
                    string: .init(contentsOf: url)
                )
            }
        }
        self.site = site
        self.library = MustacheLibrary(templates: templates)
        self.ids = Array(templates.keys)
    }

    private func render(
        template: String,
        with object: Any
    ) throws -> String? {
        guard self.ids.contains(template) else {
            throw Error.missingTemplate(template)
        }
        return library.render(object, withTemplate: template)
    }

    private func render(
        template: String,
        with object: Any,
        to destination: URL
    ) throws {
        guard ids.contains(template) else {
            throw Error.missingTemplate(template)
        }
        try library.render(
            object,
            withTemplate: template
        )?
        .minifyHTML()
        .write(
            to: destination,
            atomically: true,
            encoding: .utf8
        )
    }

    // MARK: -

    func renderSinglePage(
        page: Page,
        body: String,
        to destination: URL
    ) throws {
        let context = ContentContext(
            site: site.getContext(),
            metadata: .init(
                permalink: site.permalink(page.slug),
                title: page.meta.title,
                description: page.meta.description,
                imageUrl: page.meta.imageUrl
            ),
            content: SingleCustomPageContext(
                title: page.meta.title,
                description: page.meta.description,
                body: body
            ),
            userDefined: page.frontMatter
        )

        try render(
            template: "pages.single.page",
            with: context,
            to: destination
        )
    }

    func renderSingleTag(
        tag: Tag,
        body: String,
        to destination: URL
    ) throws {
        let formatter = DateFormatters().standard
        let context = ContentContext(
            site: site.getContext(),
            metadata: .init(
                permalink: site.permalink(tag.slug),
                title: tag.meta.title,
                description: tag.meta.description,
                imageUrl: tag.meta.imageUrl
            ),
            content: SingleTagPageContext(
                title: tag.meta.title,
                description: tag.meta.description,
                posts: .init(
                    site.postsBy(tagId: tag.id)
                        .map {
                            $0.getContext(
                                site: site,
                                formatter: formatter
                            )
                        }
                )
            ),
            userDefined: tag.frontMatter
        )

        try render(
            template: "pages.single.tag",
            with: context,
            to: destination
        )
    }

    func renderSingleAuthor(
        author: Author,
        body: String,
        to destination: URL
    ) throws {
        let formatter = DateFormatters().standard
        let context = ContentContext(
            site: site.getContext(),
            metadata: .init(
                permalink: site.permalink(author.slug),
                title: author.meta.title,
                description: author.meta.description,
                imageUrl: author.meta.imageUrl
            ),
            content: SingleAuthorPageContext(
                title: author.meta.title,
                description: author.meta.description,
                posts: .init(
                    site.postsBy(authorId: author.id)
                        .map {
                            $0.getContext(
                                site: site,
                                formatter: formatter
                            )
                        }
                )
            ),
            userDefined: author.frontMatter
        )

        try render(
            template: "pages.single.author",
            with: context,
            to: destination
        )
    }

    func renderSinglePost(
        post: Post,
        body: String,
        to destination: URL
    ) throws {
        let formatter = DateFormatters().standard
        let context = ContentContext(
            site: site.getContext(),
            metadata: .init(
                permalink: site.permalink(post.slug),
                title: post.meta.title,
                description: post.meta.description,
                imageUrl: post.meta.imageUrl
            ),
            content: SinglePostPageContext(
                title: post.meta.title,
                exceprt: post.meta.description,
                date: formatter.string(from: post.publication),
                figure: .init(
                    src: post.meta.imageUrl ?? "",
                    darkSrc: post.meta.imageUrl ?? "",
                    alt: post.meta.title,
                    title: post.meta.title
                ),
                tags: .init(
                    site.tagsBy(ids: post.tagIds)
                        .map { $0.getContext(site: site) }
                ),
                authors: .init(
                    site.authorsBy(ids: post.authorIds)
                        .map { $0.getContext(site: site) }
                ),
                body: body
            ),
            userDefined: post.frontMatter
        )

        try render(
            template: "pages.single.post",
            with: context,
            to: destination
        )
    }

    func renderAuthorsPage(
        to destination: URL
    ) throws {
        let page = site.page(id: "authors")

        let context = ContentContext(
            site: site.getContext(),
            metadata: .init(
                permalink: site.permalink(""),
                title: page?.meta.title ?? "Authors",
                description: page?.meta.description ?? "Authors page",
                imageUrl: nil
            ),
            content: AuthorsPageContext(
                authors: .init(
                    site.authors.map {
                        $0.getContext(
                            site: site
                        )
                    }
                )
            ),
            userDefined: page?.frontMatter ?? [:]
        )

        try render(
            template: "pages.authors",
            with: context,
            to: destination
        )
    }

    func renderTagsPage(
        to destination: URL
    ) throws {
        let page = site.page(id: "tags")

        let context = ContentContext(
            site: site.getContext(),
            metadata: .init(
                permalink: site.permalink(""),
                title: page?.meta.title ?? "Tags",
                description: page?.meta.description ?? "Tags page",
                imageUrl: nil
            ),
            content: TagsPageContext(
                tags: .init(
                    site.tags.map {
                        $0.getContext(
                            site: site
                        )
                    }
                )
            ),
            userDefined: page?.frontMatter ?? [:]
        )

        try render(
            template: "pages.tags",
            with: context,
            to: destination
        )
    }

    func renderHomePage(
        to destination: URL
    ) throws {
        let formatter = DateFormatters().standard
        let page = site.page(id: "home")

        let context = ContentContext(
            site: site.getContext(),
            metadata: .init(
                permalink: site.permalink(""),
                title: page?.meta.title ?? "Home",
                description: page?.meta.description ?? "Home page",
                imageUrl: nil
            ),
            content: HomePageContext(
                // TODO: first N
                posts: .init(
                    site.posts  //.prefix(2)
                        .map {
                            $0.getContext(
                                site: site,
                                formatter: formatter
                            )
                        }
                )
            ),
            userDefined: page?.frontMatter ?? [:]
        )

        try render(
            template: "pages.home",
            with: context,
            to: destination
        )
    }

    func renderNotFoundPage(
        to destination: URL
    ) throws {
        let formatter = DateFormatters().standard
        let page = site.page(id: "404")

        let context = ContentContext(
            site: site.getContext(),
            metadata: .init(
                permalink: site.permalink(""),
                title: page?.meta.title ?? "Not found",
                description: page?.meta.description ?? "Page not found",
                imageUrl: nil
            ),
            content: HomePageContext(
                // TODO: first N
                posts: .init(
                    site.posts.map {
                        $0.getContext(
                            site: site,
                            formatter: formatter
                        )
                    }
                )
            ),
            userDefined: page?.frontMatter ?? [:]
        )

        try render(
            template: "pages.404",
            with: context,
            to: destination
        )
    }

    func renderPostsPage(
        posts: [Post],
        pageIndex index: Int,
        pageCount count: Int,
        to destination: URL
    ) throws {
        let formatter = DateFormatters().standard
        let pageIndex = index + 1
        let context = ContentContext(
            site: site.getContext(),
            metadata: .init(
                permalink: site.permalink("posts/page/\(pageIndex)"),
                title: "posts page 1",
                description: "posts page 1 description",
                imageUrl: nil
            ),
            content: PostsPageContext(
                posts: .init(
                    posts.map {
                        $0.getContext(
                            site: site,
                            formatter: formatter
                        )
                    }
                ),
                pagination: .init(
                    (0..<count)
                        .map { idx in
                            let currentPageIndex = idx + 1
                            return .init(
                                name: "\(currentPageIndex)",
                                url: site.permalink(
                                    "posts/page/\(currentPageIndex)"
                                ),
                                isCurrent: index == idx
                            )
                        }
                )
            ),
            userDefined: [:]
        )

        try render(
            template: "pages.posts",
            with: context,
            to: destination
        )
    }

    func renderRSS(
        to destination: URL
    ) throws {

        let now = Date()
        let formatter = DateFormatters().rss

        let items: [RSSContext.ItemContext] = site.posts.map {
            .init(
                permalink: site.permalink(
                    $0.slug
                ),
                title: $0.meta.title,
                description: $0.meta.description,
                publicationDate: formatter.string(
                    from: $0.publication
                )
            )
        }

        let context = RSSContext(
            title: site.title,
            description: site.description,
            baseUrl: site.baseUrl,
            language: site.language,
            lastBuildDate: formatter.string(from: now),
            publicationDate: formatter.string(
                from: site.posts.first?.publication ?? now
            ),
            items: .init(items)
        )

        try render(
            template: "rss",
            with: context,
            to: destination
        )
    }

    func renderSitemap(
        to destination: URL
    ) throws {
        let formatter = DateFormatters().sitemap
        let context = SitemapContext(
            urls: .init(
                site.contents.map {
                    SitemapContext.URL(
                        location: site.permalink($0.slug),
                        lastModification: formatter.string(
                            from: $0.lastModification
                        )
                    )
                }
            )
        )

        try render(
            template: "sitemap",
            with: context,
            to: destination
        )
    }
}
