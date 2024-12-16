//
//  File.swift
//  toucan
//
//  Created by Tibor Bodecs on 2024. 10. 13..
//

import Foundation

struct RedirectRenderer {

    public enum Files {
        static let index = "index.html"
    }

    let destinationUrl: URL
    let fileManager: FileManager
    let templateRenderer: MustacheToHTMLRenderer
    let pageBundles: [PageBundle]

    func render() throws {
        for pageBundle in pageBundles {
            for redirect in pageBundle.config.redirects {

                let fileUrl =
                    destinationUrl
                    .appendingPathComponent(redirect.from)
                    .appendingPathComponent(Files.index)

                try fileManager.createParentFolderIfNeeded(for: fileUrl)

                try templateRenderer.render(
                    template: "redirect",
                    with: RedirectContext(
                        url: pageBundle.permalink,
                        code: redirect.code.rawValue
                    ),
                    to: fileUrl
                )
            }
        }
    }
}
