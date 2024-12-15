//
//  File.swift
//
//
//  Created by Tibor Bodecs on 23/05/2024.
//

import Markdown
import Foundation

struct HTMLRendererDelegate: MarkdownRenderer.Delegate {

    let config: Config
    let pageBundle: PageBundle

    func linkAttributes(_ link: String?) -> [String: String] {
        var attributes: [String: String] = [:]
        guard let link, !link.isEmpty else {
            return attributes
        }

        if
            !link.hasPrefix("."),
            !link.hasPrefix("/"),
            !link.hasPrefix(config.site.baseUrl)
        {
            attributes["target"] = "_blank"
        }
        return attributes
    }

    func imageOverride(_ image: Image) -> String? {
        guard
            let source = image.source
        else {
            return nil
        }
        let path = pageBundle.resolveAsset(path: source)

        var title = ""
        if let ttl = image.title {
            title = #" title="\#(ttl)""#
        }

        return """
                <img src="\(path)" alt="\(image.plainText)"\(title)>
            """
    }
}
