//
//  File.swift
//  toucan
//
//  Created by Tibor Bodecs on 2024. 10. 14..
//

import Foundation

struct SiteBundle {
    
//    enum Keys {
//        static let name = "name"
//    }

    let userDefined: [String: Any]

    init(
        userDefined: [String: Any]
    ) {
        self.userDefined = userDefined
    }

    init(_ dict: [String: Any]) {
        self.userDefined = dict
    }
}

extension SiteBundle {

//    var name: String? { userDefined.string(Keys.name) }
}
