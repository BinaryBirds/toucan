//
//  File.swift
//  
//
//  Created by Tibor Bodecs on 21/06/2024.
//

import Foundation

struct OutputRenderer {

    let site: Site

    let templatesUrl: URL
    let overridesUrl: URL
    let destinationUrl: URL

    let fileManager: FileManager = .default

    func render() throws {
        let renderer = try MustacheToHTMLRenderer(
            templatesUrl: templatesUrl,
            overridesUrl: overridesUrl
        )
        // render pages
        let home = home()
        let notFound = notFound()
        try render(renderer, home)
        try render(renderer, notFound)
        
        // render rss & sitemap
        let rss = rss()
        let sitemap = sitemap()
        try render(renderer, rss)
        try render(renderer, sitemap)
        
        // render blog
        if let renderable = blogHome() {
            try render(renderer, renderable)
        }

        // render authors
        if let renderable = authorList() {
            try render(renderer, renderable)
        }
        for renderable in authorDetails() {
            try render(renderer, renderable)
        }
        
        // render tags
        if let renderable = tagList() {
            try render(renderer, renderable)
        }
        for renderable in tagDetails() {
            try render(renderer, renderable)
        }
        
        // render posts
        for renderable in postListPaginated() {
            try render(renderer, renderable)
        }
        for renderable in postDetails() {
            try render(renderer, renderable)
        }
        
        // custom pages
        for renderable in customPages() {
            try render(renderer, renderable)
        }
        
        // docs
        if let docsHome = docsHome() {
            try render(renderer, docsHome)
        }
        
        // docs categories
        if let docsCategoryList = docsCategoryList() {
            try render(renderer, docsCategoryList)
        }
        for renderable in docsCategoryDetails() {
            try render(renderer, renderable)
        }
        
        // docs guides
        if let docsGuidList = docsGuideList() {
            try render(renderer, docsGuidList)
        }
        for renderable in docsGuideDetails() {
            try render(renderer, renderable)
        }
        
        // TODO: move this
        struct Redirect: Output {
            let url: String
        }
        for content in site.source.materials.all() {
            for slug in content.redirects {
                try render(renderer,
                    .init(
                        template: "redirect",
                        context: Redirect(
                            url: site.permalink(content.slug)
                        ),
                        destination: site.destinationUrl
                            .appendingPathComponent(slug)
                            .appendingPathComponent(Toucan.Files.index)
                    )
                )
            }
        }
    }

    // MARK: -

    func render<T>(
        _ renderer: MustacheToHTMLRenderer,
        _ renderable: Renderable<T>
    ) throws {
        try fileManager.createParentFolderIfNeeded(
            for: renderable.destination
        )
        try renderer.render(
            template: renderable.template,
            with: renderable.context,
            to: renderable.destination
        )
    }
    
    // MARK: - pages
    
    func getOutputHTMLContext<T>(
        material: SourceMaterial,
        context: T
    ) -> HTML<T> {
        let renderer = MarkdownToHTMLRenderer(
            delegate: HTMLRendererDelegate(
                config: site.contents.config,
                material: material
            )
        )
        
        return .init(
            site: .init(
                baseUrl: site.contents.config.site.baseUrl,
                title: site.contents.config.site.title,
                description: site.contents.config.site.description,
                language: site.contents.config.site.language
            ),
            page: .init(
                metadata: .init(
                    slug: material.slug,
                    permalink: site.permalink(material.slug),
                    title: material.title,
                    description: material.description,
                    imageUrl: material.imageUrl().map { site.permalink($0) }
                ),
                css: material.cssUrls(),
                js: material.jsUrls(),
                data: material.data,
                context: context,
                content: renderer.render(
                    markdown: material.markdown
                )
            ),
            userDefined: site.contents.config.site.userDefined
                .recursivelyMerged(with: material.userDefined),
            year: site.currentYear
        )
    }
    
    func notFound() -> Renderable<HTML<Void>> {
        let material = site.source.materials.pages.main.notFound
        let context = getOutputHTMLContext(
            material: material,
            context: ()
        )
        return .init(
            template: material.template,
            context: context,
            destination: destinationUrl
                .appendingPathComponent(Toucan.Files.notFound)
        )
    }
    
    func home() -> Renderable<HTML<Context.Main.Home>> {
        let material = site.source.materials.pages.main.home
        let context = getOutputHTMLContext(
            material: material,
            context: Context.Main.Home(
                featured: site.contents.blog.featuredPosts().map { $0.context(site: site) },
                posts: site.contents.blog.latestPosts().map { $0.context(site: site) },
                authors: site.contents.blog.sortedAuthors().map { $0.context(site: site) },
                tags: site.contents.blog.sortedTags().map { $0.context(site: site) },
                pages: []
            )
        )
        return .init(
            template: material.template,
            context: context,
            destination: destinationUrl
                .appendingPathComponent(Toucan.Files.index)
        )
    }
    
    // MARK: - custom pages
    
    func customPages() -> [Renderable<HTML<Context.Pages.Detail>>] {
        site.contents.pages.custom.map { page in
            let material = page.material
            let context = getOutputHTMLContext(
                material: material,
                context: Context.Pages.Detail(
                    // TODO: use page content
                    page: .init(
                        slug: material.slug,
                        permalink: site.permalink(material.slug),
                        title: material.title,
                        description: material.description,
                        imageUrl: material.imageUrl(),
                        userDefined: [:] //TODO: !!!
                    )
                )
            )
            
            return .init(
                template: material.template,
                context: context,
                destination: destinationUrl
                    .appendingPathComponent(material.slug)
                    .appendingPathComponent(Toucan.Files.index)
            )
        }
    }
    
    // MARK: - blog
    
    func blogHome() -> Renderable<HTML<Context.Blog.Home>>? {
        guard let material = site.source.materials.pages.blog.home else {
            return nil
        }
        let context = getOutputHTMLContext(
            material: material,
            context: Context.Blog.Home(
                featured: site.contents.blog.featuredPosts().map { $0.context(site: site) },
                posts: site.contents.blog.latestPosts().map { $0.context(site: site) },
                authors: site.contents.blog.sortedAuthors().map { $0.context(site: site) },
                tags: site.contents.blog.sortedTags().map { $0.context(site: site) }
            )
        )
        return .init(
            template: material.template,
            context: context,
            destination: destinationUrl
                .appendingPathComponent(material.slug)
                .appendingPathComponent(Toucan.Files.index)
        )
    }
    
    
    // MARK: - authors
    
    func authorList() -> Renderable<HTML<Context.Blog.Author.List>>? {
        guard let material = site.source.materials.pages.blog.authors else {
            return nil
        }
        let context = getOutputHTMLContext(
            material: material,
            context: Context.Blog.Author.List(
                authors: site.contents.blog.sortedAuthors().map {
                    $0.context(site: site)
                }
            )
        )
        return .init(
            template: material.template,
            context: context,
            destination: destinationUrl
                .appendingPathComponent(material.slug)
                .appendingPathComponent(Toucan.Files.index)
        )
    }
    
    func authorDetails() -> [Renderable<HTML<Context.Blog.Author.Detail>>] {
        site.contents.blog.authors.map { author in
            let material = author.material
            let context = getOutputHTMLContext(
                material: material,
                context: Context.Blog.Author.Detail(
                    author: author.context(site: site),
                    posts: author.posts.map { $0.context(site: site) }
                )
            )
            return .init(
                template: material.template,
                context: context,
                destination: destinationUrl
                    .appendingPathComponent(material.slug)
                    .appendingPathComponent(Toucan.Files.index)
            )
        }
    }
    
    // MARK: - tags
    
    func tagList() -> Renderable<HTML<Context.Blog.Tag.List>>? {
        guard let material = site.source.materials.pages.blog.tags else {
            return nil
        }
        let context = getOutputHTMLContext(
            material: material,
            context: Context.Blog.Tag.List(
                tags: site.contents.blog.sortedTags().map {
                    $0.context(site: site)
                }
            )
        )
        return .init(
            template: material.template,
            context: context,
            destination: destinationUrl
                .appendingPathComponent(material.slug)
                .appendingPathComponent(Toucan.Files.index)
        )
    }
    
    
    func tagDetails() -> [Renderable<HTML<Context.Blog.Tag.Detail>>] {
        site.contents.blog.tags.map { tag in
            let material = tag.material
            let context = getOutputHTMLContext(
                material: material,
                context: Context.Blog.Tag.Detail(
                    tag: tag.context(site: site),
                    posts: tag.posts.map { $0.context(site: site) }
                )
            )
            return .init(
                template: material.template,
                context: context,
                destination: destinationUrl
                    .appendingPathComponent(material.slug)
                    .appendingPathComponent(Toucan.Files.index)
            )
        }
    }
    
    // MARK: - post
    
    func postListPaginated(
    ) -> [Renderable<HTML<Context.Blog.Post.List>>] {
        guard let posts = site.source.materials.pages.blog.posts else {
            return []
        }

        let pageLimit = 10 // TODO: add config
        let pages = site.contents.blog.sortedPosts().chunks(ofCount: pageLimit)
        
        func replace(
            _ number: Int,
            _ value: String
        ) -> String {
            value.replacingOccurrences(
                of: "{{number}}",
                with: String(number)
            )
        }

        var result: [Renderable<HTML<Context.Blog.Post.List>>] = []
        for (index, postsChunk) in pages.enumerated() {
            let pageNumber = index + 1
            
            let title = replace(pageNumber, posts.title)
            let description = replace(pageNumber, posts.description)
            let slug = replace(pageNumber, posts.slug)

            let material = posts.updated(
                title: title,
                description: description,
                slug: slug
            )
            let context = getOutputHTMLContext(
                material: material,
                context: Context.Blog.Post.List(
                    posts: postsChunk.map { $0.context(site: site) },
                    pagination: (1...pages.count)
                        .map {
                            .init(
                                number: $0,
                                total: pages.count,
                                slug: replace($0, posts.slug),
                                permalink: site.permalink(
                                    replace($0, posts.slug)
                                ),
                                isCurrent: pageNumber == $0
                            )
                        }
                )
            )

            let r = Renderable<HTML<Context.Blog.Post.List>>(
                template: material.template,
                context: context,
                destination: destinationUrl
                    .appendingPathComponent(slug)
                    .appendingPathComponent(Toucan.Files.index)
            )
            
            result.append(r)
        }
        return result
    }
    
    func postDetails() -> [Renderable<HTML<Context.Blog.Post.Detail>>] {
        site.contents.blog.posts.map { post in
            let material = post.material
            let context = getOutputHTMLContext(
                material: material,
                context: Context.Blog.Post.Detail(
                    post: post.context(site: site),
                    related: site.contents.blog.related(post: post).map { $0.context(site: site) },
                    moreByAuthor: site.contents.blog.more(post: post).map { $0.context(site: site) },
                    next: site.contents.blog.nextPost(post).map { $0.context(site: site) },
                    prev: site.contents.blog.prevPost(post).map { $0.context(site: site) }
                )
            )
            return .init(
                template: material.template,
                context: context,
                destination: destinationUrl
                    .appendingPathComponent(material.slug)
                    .appendingPathComponent(Toucan.Files.index)
            )
        }
    }

    

    // MARK: - docs
    
    func docsHome() -> Renderable<HTML<Context.Docs.HomePage>>? {
        guard let material = site.source.materials.pages.docs.home else {
            return nil
        }
        let context = getOutputHTMLContext(
            material: material,
            context: Context.Docs.HomePage(
                categories: site.contents.docs.categories.map { category in
                    category.context(
                        site: site,
                        guides: site.contents.docs.guides(category: category)
                    )
                },
                guides: site.contents.docs.guides.map { $0.context(site: site) }
            )
        )

        return .init(
            template: material.template,
            context: context,
            destination: destinationUrl
                .appendingPathComponent(material.slug)
                .appendingPathComponent(Toucan.Files.index)
        )
    }
    
    func docsCategoryList(
    ) -> Renderable<HTML<Context.Docs.Category.ListPage>>? {
        guard let material = site.source.materials.pages.docs.categories else {
            return nil
        }
        let context = getOutputHTMLContext(
            material: material,
            context: Context.Docs.Category.ListPage(
                categories: site.contents.docs.categories.map { category in
                    category.context(
                        site: site,
                        guides: site.contents.docs.guides(category: category)
                    )
                }
            )
        )
        return .init(
            template: material.template,
            context: context,
            destination: destinationUrl
                .appendingPathComponent(material.slug)
                .appendingPathComponent(Toucan.Files.index)
        )
    }
    
    func docsCategoryDetails(
        
    ) -> [Renderable<HTML<Context.Docs.Category.DetailPage>>] {
        site.contents.docs.categories.map { item in
            let material = item.material
            let context = getOutputHTMLContext(
                material: material,
                context: Context.Docs.Category.DetailPage(
                    category: .init(
                        slug: "",
                        permalink: "",
                        title: "",
                        description: "",
                        imageUrl: nil,
                        date: "",
                        guides: [],
                        userDefined: [:]
                    ),
                    guides: []
                )
            )
            
            return .init(
                template: material.template,
                context: context,
                destination: destinationUrl
                    .appendingPathComponent(material.slug)
                    .appendingPathComponent(Toucan.Files.index)
            )
        }
    }
    
    // MARK: - guides
    
    func docsGuideList(
    ) -> Renderable<HTML<Context.Docs.Guide.ListPage>>? {
        guard let material = site.source.materials.pages.docs.guides else {
            return nil
        }
        let context = getOutputHTMLContext(
            material: material,
            context: Context.Docs.Guide.ListPage(
                guides: site.contents.docs.guides.map { $0.context(site: site) }
            )
        )
        return .init(
            template: material.template,
            context: context,
            destination: destinationUrl
                .appendingPathComponent(material.slug)
                .appendingPathComponent(Toucan.Files.index)
        )
    }
    
    func docsGuideDetails(
    ) -> [Renderable<HTML<Context.Docs.Guide.DetailPage>>] {
        site.contents.docs.guides.map { item in
            let material = item.material
            let context = getOutputHTMLContext(
                material: material,
                context: Context.Docs.Guide.DetailPage(
                    categories: site.contents.docs.categories.map { category in
                        category.context(
                            site: site,
                            guides: site.contents.docs.guides(category: category)
                        )
                    },
                    guide: item.context(
                        site: site
                    )
                )
            )
            return .init(
                template: material.template,
                context: context,
                destination: destinationUrl
                    .appendingPathComponent(material.slug)
                    .appendingPathComponent(Toucan.Files.index)
            )
        }
    }
    
    // MARK: - rss
    
    func rss() -> Renderable<RSS> {
        let items: [RSS.Item] = site.contents.blog.sortedPosts().map { item in
            let material = item.material
            return .init(
                permalink: site.permalink(material.slug),
                title: material.title,
                description: material.description,
                publicationDate: site.rssDateFormatter.string(
                    from: item.published
                )
            )
        }
        
        let publicationDate = items.first?.publicationDate ?? site.rssDateFormatter.string(from: .init())
        
        let context = RSS(
            title: site.contents.config.site.title,
            description: site.contents.config.site.description,
            baseUrl: site.contents.config.site.baseUrl,
            language: site.contents.config.site.language,
            lastBuildDate: site.rssDateFormatter.string(from: .init()),
            publicationDate: publicationDate,
            items: items
        )
        
        return .init(
            template: "rss",
            context: context,
            destination: destinationUrl
                .appendingPathComponent(Toucan.Files.rss)
        )
    }
    
    
    // MARK: - sitemap
    
    func sitemap() -> Renderable<Sitemap> {
        let context = Sitemap(
            urls: site.source.materials.all()
                .map { content in
                        .init(
                            location: site.permalink(content.slug),
                            lastModification: site.sitemapDateFormatter.string(
                                from: content.lastModification
                            )
                        )
                }
        )
        return .init(
            template: "sitemap",
            context: context,
            destination: destinationUrl
                .appendingPathComponent(Toucan.Files.sitemap)
        )
    }
}
