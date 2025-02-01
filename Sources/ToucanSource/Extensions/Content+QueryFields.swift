//
//  File.swift
//  toucan
//
//  Created by Tibor Bodecs on 2025. 01. 31..
//

import Foundation
import ToucanModels

extension Content {

    // relations can be queried too
    // TODO: maybe add support for user defined values?
    var queryFields: [String: PropertyValue] {
        var fields = properties

        for (key, relation) in relations {
            switch relation.type {
            case .one:
                fields[key] = .string(relation.identifiers[0])
            case .many:
                fields[key] = .init(relation.identifiers)
            }
        }

        // add identifier & slug explicitly
        fields["id"] = .string(id)
        fields["slug"] = .string(slug)
        return fields
    }
}
