//
//  File.swift
//  toucan
//
//  Created by Tibor Bodecs on 2024. 10. 28..
//

import Foundation
import Logging

struct SEOValidator {

    let logger: Logger

    func validate(
        pageBundle: PageBundle
    ) {
        guard pageBundle.contentType.id != ContentType.pagination.id else {
            return
        }
        let metadata: Logger.Metadata = [
            "type": "\(pageBundle.contentType.id)",
            "slug": "\(pageBundle.slug)",
        ]

        // check title
        if pageBundle.title.count < 55 {
            logger.warning(
                "Title is too short, use minimum 55 characters.",
                metadata: metadata
            )
        }
        if pageBundle.title.count > 65 {
            logger.warning(
                "Title is too long, use maximum 65 characters.",
                metadata: metadata
            )
        }
        if pageBundle.title.count > 70 {
            logger.error(
                "Title is way too long, use maximum 70 characters.",
                metadata: metadata
            )
        }
        // check description
        if pageBundle.description.count < 50 {
            logger.warning(
                "Description is too short, use minimum 55 characters.",
                metadata: metadata
            )
        }
        if pageBundle.description.count > 160 {
            logger.warning(
                "Description is too long, use maximum 65 characters.",
                metadata: metadata
            )
        }
        if pageBundle.description.count > 165 {
            logger.error(
                "Description is way too long, use maximum 70 characters.",
                metadata: metadata
            )
        }

        // check keyword
        let keyword = pageBundle.frontMatter.string("keyword")
        if let keyword {
            if !pageBundle.title.contains(keyword) {
                logger.warning(
                    "Title does not contain keyword: `\(keyword)`.",
                    metadata: metadata
                )
            }
            if !pageBundle.description.contains(keyword) {
                logger.warning(
                    "Description does not contain keyword: `\(keyword)`.",
                    metadata: metadata
                )
            }
        }

    }
}