//
//  File.swift
//  toucan
//
//  Created by Tibor Bodecs on 2024. 10. 14..
//

import Foundation
import FileManagerKit
import Logging

public struct SiteBundleLoader {

    /// An enumeration representing possible errors that can occur while loading the configuration.
    public enum Error: Swift.Error {
        /// Indicates that a required configuration file is missing at the specified URL.
        case missing(URL)
    }

    /// The URL of the source files.
    let sourceUrl: URL
    /// The configuration.
    let config: Config
    /// A file loader used for loading files.
    let fileLoader: FileLoader
    /// The base URL to use for the configuration.
    let baseUrl: String?
    /// The logger instance
    let logger: Logger

    func load() throws -> SiteBundle {
        let siteUrl =
            sourceUrl
            .appendingPathComponent(config.contents.folder)
        let siteFileUrl =
            siteUrl
            .appendingPathComponent("index")

        logger.debug(
            "Loading site bundle file from: `\(siteUrl.absoluteString)`."
        )

        do {
            let contents = try fileLoader.loadContents(at: siteFileUrl)
            let yaml = try contents.decodeYaml()
            return .init(yaml)
        }
        catch FileLoader.Error.missing(let url) {
            throw Error.missing(url)
        }
    }
}
