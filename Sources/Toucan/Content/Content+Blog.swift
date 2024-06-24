//
//  File.swift
//  
//
//  Created by Tibor Bodecs on 21/06/2024.
//

import Foundation

extension Site.Content {
    
    struct Blog {

        struct Post {
            let content: Source.Content
            let published: Date
            let tags: [String]
            let authors: [String]
            let featured: Bool
            
            init(
                content: Source.Content,
                config: Source.Config,
                dateFormatter: DateFormatter
            ) {
                self.content = content
                
                dateFormatter.dateFormat = config.site.dateFormat

                if
                    let rawDate = content.frontMatter["publication"] as? String,
                    let date = dateFormatter.date(from: rawDate)
                {
                    self.published = date
                }
                else {
                    self.published = Date()
                }
                
                let tags = content.frontMatter["tags"] as? [String] ?? []
                self.tags = tags.map { slug in
                    return slug.safeSlug(
                        prefix: config.contents.blog.tags.slugPrefix
                    )
                }
                
                let authors = content.frontMatter["authors"] as? [String] ?? []
                self.authors = authors.map { slug in
                    return slug.safeSlug(
                        prefix: config.contents.blog.authors.slugPrefix
                    )
                }
                
                self.featured = content.frontMatter["featured"] as? Bool ?? false
            }
            
            func context(site: Site) -> Context.Blog.Post {
                .init(
                    permalink: site.permalink(content.slug),
                    title: content.title,
                    excerpt: content.description,
                    date: "",
                    figure: nil,
                    tags: [],
                    authors: [],
                    readingTime: site.readingTime(content.markdown),
                    featured: featured,
                    userDefined: [:]
                )
            }
        }

        struct Author {
            let content: Source.Content
            let posts: [Blog.Post]

            func context(site: Site) -> Context.Blog.Author {
                .init(
                    permalink: site.permalink(content.slug),
                    title: content.title,
                    description: content.description,
                    figure: nil,
                    numberOfPosts: posts.count,
                    userDefined: [:],
                    markdown: site.render(
                        markdown: content.markdown,
                        folder: content.assetsFolder
                    )
                )
            }
        }

        struct Tag {
            let content: Source.Content
            let posts: [Blog.Post]
            
            func context(site: Site) -> Context.Blog.Tag {
                .init(
                    permalink: site.permalink(content.slug),
                    title: content.title,
                    description: content.description,
                    figure: nil,
                    numberOfPosts: posts.count,
                    userDefined: [:],
                    markdown: site.render(
                        markdown: content.markdown,
                        folder: content.assetsFolder
                    )
                )
            }
        }

        let posts: [Post]
        let authors: [Author]
        let tags: [Tag]
        
        func sortedAuthors() -> [Author] {
            authors.sorted {
                $0.content.title.localizedCaseInsensitiveCompare($1.content.title) == .orderedAscending
            }
        }

        func sortedTags() -> [Tag] {
            tags.sorted {
                $0.content.title.localizedCaseInsensitiveCompare($1.content.title) == .orderedAscending
            }
        }

        func sortedPosts() -> [Post] {
            posts
                .sorted { $0.published > $1.published }
        }

        func featuredPosts() -> [Post] {
            posts
                .filter { $0.featured }
                .sorted { $0.published > $1.published }
        }
    }
    
}


//
//    func nextPost(for slug: String) -> PostState? {
//        let posts = content.blog.post.sortedContents
//
//        if let index = posts.firstIndex(where: { $0.slug == slug }) {
//            if index > 0 {
//                let post = posts[index - 1]
//                return postState(
//                    for: post,
//                    authors: content.blog.author.contentsBy(
//                        slugs: post.authorSlugs
//                    ),
//                    tags: content.blog.tag.contentsBy(
//                        slugs: post.tagSlugs
//                    )
//                )
//            }
//        }
//        return nil
//    }
//
//    func prevPost(for slug: String) -> PostState? {
//        let posts = content.blog.post.sortedContents
//
//        if let index = posts.firstIndex(where: { $0.slug == slug }) {
//            if index < posts.count - 1 {
//                let post = posts[index + 1]
//                return postState(
//                    for: post,
//                    authors: content.blog.author.contentsBy(
//                        slugs: post.authorSlugs
//                    ),
//                    tags: content.blog.tag.contentsBy(
//                        slugs: post.tagSlugs
//                    )
//                )
//            }
//        }
//        return nil
//    }
//
//    func relatedPosts(for slug: String) -> [PostState] {
//        var result: [PostState] = []
//
//        let posts = content.blog.post.sortedContents
//        if let index = posts.firstIndex(where: { $0.slug == slug }) {
//            let post = posts[index]
//            for tagSlug in post.tagSlugs {
//                result += content.blog.post.contentsBy(tagSlug: tagSlug)
//                    .filter { $0.slug != slug }
//                    .map {
//                        postState(
//                            for: $0,
//                            authors: content.blog.author.contentsBy(
//                                slugs: $0.authorSlugs
//                            ),
//                            tags: content.blog.tag.contentsBy(
//                                slugs: $0.tagSlugs
//                            )
//                        )
//                    }
//            }
//        }
//        return Array(result.shuffled().prefix(5))
//    }
//
//    func moreByPosts(for slug: String) -> [PostState] {
//        var result: [PostState] = []
//
//        let posts = content.blog.post.sortedContents
//        if let index = posts.firstIndex(where: { $0.slug == slug }) {
//            let post = posts[index]
//            for authorSlug in post.authorSlugs {
//                result += content.blog.post.contentsBy(authorSlug: authorSlug)
//                    .filter { $0.slug != slug }
//                    .map {
//                        postState(
//                            for: $0,
//                            authors: content.blog.author.contentsBy(
//                                slugs: $0.authorSlugs
//                            ),
//                            tags: content.blog.tag.contentsBy(
//                                slugs: $0.tagSlugs
//                            )
//                        )
//                    }
//            }
//        }
//        return Array(result.shuffled().prefix(5))
//    }