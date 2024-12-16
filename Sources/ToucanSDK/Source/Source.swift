//
//  File.swift
//  toucan
//
//  Created by Tibor Bodecs on 2024. 10. 11..
//

import Foundation

struct Source {

    let url: URL
    let config: Config
    
    var contentsUrl: URL {
        url.appendingPathComponent(config.contents.folder)
    }

    /// Global site assets.
    var assetsUrl: URL {
        contentsUrl
            .appendingPathComponent(config.contents.assets.folder)
    }

    var themesUrl: URL {
        url.appendingPathComponent(config.themes.folder)
    }

    var transformersUrl: URL {
        url.appendingPathComponent(config.transformers.folder)
    }

    // MARK: - theme

    var currentThemeUrl: URL {
        themesUrl.appendingPathComponent(config.themes.use)
    }

    var currentThemeAssetsUrl: URL {
        currentThemeUrl.appendingPathComponent(config.themes.assets.folder)
    }

    var currentThemeTemplatesUrl: URL {
        currentThemeUrl.appendingPathComponent(config.themes.templates.folder)
    }

    var currentThemeTypesUrl: URL {
        currentThemeUrl.appendingPathComponent(config.themes.types.folder)
    }

    // MARK: - theme overrides

    var currentThemeOverrideUrl: URL {
        themesUrl.appendingPathComponent(config.themes.overrides.folder)
    }

    var currentThemeOverrideAssetsUrl: URL {
        currentThemeOverrideUrl.appendingPathComponent(
            config.themes.assets.folder
        )
    }

    var currentThemeOverrideTemplatesUrl: URL {
        currentThemeOverrideUrl.appendingPathComponent(
            config.themes.templates.folder
        )
    }

    var currentThemeOverrideTypesUrl: URL {
        currentThemeOverrideUrl.appendingPathComponent(
            config.themes.types.folder
        )
    }
}

