//
//  File.swift
//  toucan
//
//  Created by Viasz-Kádi Ferenc on 2024. 10. 15..
//

import Foundation
import ShellKit
import Logging

/// Executes the pipeline on the provided markdown content, processing it through multiple transformation steps.
/// The result is either raw transformed content or rendered HTML, depending on the pipeline configuration.
///
/// - Returns: The transformed and optionally rendered content as a string.
/// - Throws: An error if the markdown file could not be written, commands could not be executed, or the file could not be deleted.
struct PipelineExecutor {
    let pipeline: Config.Transformers.Pipeline
    let pageBundle: PageBundle
    let source: Source
    let fileManager: FileManager
    let logger: Logger

    func execute() throws -> String {
        let markdown = pageBundle.markdown.dropFrontMatter()
        var contents = ""

        // Create a temporary directory URL
        let tempDirectoryURL = fileManager.temporaryDirectory
        let fileName = UUID().uuidString
        let fileURL = tempDirectoryURL.appendingPathComponent(fileName)
        try markdown.write(to: fileURL, atomically: true, encoding: .utf8)

        let shell = Shell(env: ProcessInfo.processInfo.environment)

        for run in pipeline.run {
            let runUrl = source.transformersUrl
                .appendingPathComponent(run.name)
            guard fileManager.fileExists(at: runUrl) else {
                continue
            }

            let bin = runUrl.path
            let options = [
                "file": fileURL.path,
                "id": pageBundle.contextAwareIdentifier,
                "slug": pageBundle.slug,
            ]
            .map { #"--\#($0) "\#($1)""# }
            .joined(separator: " ")

            do {
                let cmd = #"\#(bin) \#(options)"#
                let log = try shell.run(cmd)
                if !log.isEmpty {
                    logger.debug("\(log)")
                }
            }
            catch {
                logger.error("\(String(describing: error))")
            }
        }

        contents = try String(contentsOf: fileURL, encoding: .utf8)
        try fileManager.delete(at: fileURL)
        return contents
    }
}
