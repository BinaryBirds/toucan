//
//  File.swift
//
//
//  Created by Tibor Bodecs on 03/05/2024.
//

import Algorithms

struct Site {

    let baseUrl: String
    let title: String
    let description: String
    let language: String?

    let pages: [Page]
    let posts: [Post]
    let authors: [Author]
    let tags: [Tag]

    init(
        baseUrl: String,
        title: String,
        description: String,
        language: String? = nil,
        pages: [Page],
        posts: [Post],
        authors: [Author],
        tags: [Tag]
    ) {
        self.baseUrl = baseUrl
        self.title = title
        self.description = description
        self.language = language
        self.pages = pages.sorted { $0.meta.title > $1.meta.title }
        self.posts = posts.sorted { $0.publication > $1.publication }
        self.authors = authors.sorted { $0.meta.title > $1.meta.title }
        self.tags = tags.sorted { $0.meta.title > $1.meta.title }
    }
}

extension Site {

    var contents: [ContentType] {
        pages + posts + authors + tags
    }

    var postChunks: ChunksOfCountCollection<[Post]> {
        posts.chunks(ofCount: 2)
    }

    func permalink(_ value: String) -> String {
        let uncheckedValue = baseUrl + value
        if uncheckedValue.hasSuffix("/") {
            return uncheckedValue
        }
        return uncheckedValue + "/"
    }

    func postsBy(tagId: String) -> [Post] {
        posts.filter { $0.tagIds.contains(tagId) }
    }

    func postsBy(authorId: String) -> [Post] {
        posts.filter { $0.authorIds.contains(authorId) }
    }

    func page(id: String) -> Page? {
        pages.filter { $0.id == id }.first
    }

}
