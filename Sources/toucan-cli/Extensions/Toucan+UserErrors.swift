//
//  File.swift
//  toucan
//
//  Created by Tibor Bodecs on 2024. 10. 07..
//

import ToucanSDK
import Logging

extension Toucan {

    @discardableResult
    func generateAndLogErrors(_ logger: Logger) -> Bool {
        do {
            try generate()
            return true
        }
        catch let error as FileLoader.Error {
            switch error {
            case .missing(let url):
                logger.error(
                    "Missing file at: `\(url.absoluteString)`."
                )
            case .file(let error, let url):
                let message = "File error at: `\(url.absoluteString)`."
                let metadata: Logger.Metadata = [
                    "description": "\(String(describing: error))"
                ]
                logger.error(.init(stringLiteral: message), metadata: metadata)
            }
        }
        catch let error as ConfigLoader.Error {
            switch error {
            case .missing(let url):
                logger.error(
                    "Missing `config.yml` file at: `\(url.absoluteString)`."
                )
            }
        }
        catch let error as YamlParser.Error {
            switch error {
            case .yaml(let value):
                logger.error("YAML parser error: `\(value)`")
            }
        }
        catch let error as DecodingError {
            switch error {
            case .dataCorrupted(let context):
                let underlyingError = context.underlyingError ?? error
                let description = String(describing: underlyingError)
                let message = "YAML corrupted: `\(description)`"
                logger.error(.init(stringLiteral: message))
            case .typeMismatch(_, let context):
                let underlyingError = context.underlyingError ?? error
                let description = String(describing: underlyingError)
                let message = "YAML type mismatch: `\(description)`"
                logger.error(.init(stringLiteral: message))
            default:
                logger.error("\(String(describing: error))")
            }
        }
        catch let error as PageBundleLoader.Error {
            switch error {
            case .pageBundle(let error):
                logger.error(
                    "Page bundle error: `\(String(describing: error))`"
                )
            }
        }
        catch let error as MustacheToHTMLRenderer.Error {
            switch error {
            case .missingTemplate(let value):
                logger.error(
                    "Missing template file: `\(value)`"
                )
            }
        }
        catch let error as SiteBundleLoader.Error {
            switch error {
            case .missing(let url):
                logger.error(
                    "Missing site file at: `\(url.absoluteString)`."
                )
            }
        }
        catch {
            logger.error("\(String(describing: error))")
        }

        return false
    }
}
