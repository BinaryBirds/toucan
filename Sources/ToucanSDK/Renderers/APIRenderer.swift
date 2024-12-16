//
//  File.swift
//
//
//  Created by Tibor Bodecs on 21/06/2024.
//

import Foundation
import Logging
import Algorithms

struct APIRenderer {

    public enum Files {
        static let index = "index.html"
        static let notFound = "404.html"
    }

    let source: Source
    let destinationUrl: URL
    let fileManager: FileManager = .default
    let contextStore: ContextStore
    let logger: Logger

    init(
        source: Source,
        destinationUrl: URL,
        logger: Logger
    ) throws {
        self.source = source
        self.destinationUrl = destinationUrl
        self.logger = logger

        self.contextStore = .init(
            sourceConfig: source.sourceConfig,
            contentTypes: source.contentTypes,
            pageBundles: source.pageBundles,
            blockDirectives: source.blockDirectives,
            logger: logger
        )
    }

    // MARK: - render related methods

    func render() throws {
        let apiUrl = destinationUrl.appendingPathComponent("api")
        // TODO: check if exists
        try fileManager.createDirectory(at: apiUrl)

        //        let globalContext = contextStore.getPageBundlesForSiteContext()

        //        let siteContext = globalContext.mapValues {
        //            $0.map { contextStore.fullContext(for: $0) }
        //        }

        //        let x: [String: Any] = [:]
        let encoder = JSONEncoder()
        encoder.outputFormatting = [
            .prettyPrinted,
            .sortedKeys,
            .withoutEscapingSlashes,
        ]
        for contentType in source.contentTypes {
            guard let api = contentType.api, !api.isEmpty else {
                continue
            }
            let url =
                apiUrl
                .appendingPathComponent(api)
                .appendingPathExtension("json")

            //            print(url)
            //            print(contentType.id)

            let bundles = source.pageBundles
                .filter { $0.contentType.id == contentType.id }
                //                .map { $0.baseContext }
                .map {
                    contextStore.fullContext(for: $0)
                }
                .map { $0.mapValues { JSON(value: $0) } }

            let data = try encoder.encode(bundles)
            //            print(String(data: data, encoding: .utf8)!)
            try data.write(to: url)
        }
    }
}
