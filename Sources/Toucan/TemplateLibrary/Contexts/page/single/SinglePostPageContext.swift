//
//  File 2.swift
//
//
//  Created by Tibor Bodecs on 10/05/2024.
//

struct SinglePostPageContext {
    let title: String
    let exceprt: String
    let date: String
    let figure: FigureContext?
    let tags: ArrayContext<TagContext>
    let authors: ArrayContext<AuthorContext>
    let body: String
}