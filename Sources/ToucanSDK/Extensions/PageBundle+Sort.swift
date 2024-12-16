//
//  File.swift
//  toucan
//
//  Created by Viasz-Kádi Ferenc on 2024. 10. 17..
//

import Foundation

extension PageBundle {

    /// Compares two `PageBundle` instances for sorting based on a specified front matter key and order.
    ///
    /// - Parameters:
    ///   - rhs: The `PageBundle` instance to compare with.
    ///   - frontMatterKey: The key in the front matter to use for comparison.
    ///   - order: The order (`asc` or `desc`) in which to perform the comparison.
    /// - Returns: A Boolean value indicating whether the current `PageBundle` instance should be ordered before (`true`) or after (`false`) the rhs instance.
//    func compareForSorting(
//        for rhs: PageBundle,
//        frontMatterKey: String,
//        order: ContentType.Order
//    ) -> Bool {
//        guard
//            let lhsField = frontMatter[frontMatterKey],
//            let rhsField = rhs.frontMatter[frontMatterKey]
//        else {
//            return false
//        }
//
//        switch order {
//        case .asc:
//            return compareValuesAscending(lhsField, rhsField)
//        case .desc:
//            return !compareValuesAscending(lhsField, rhsField)
//        }
//    }
}

/// Compares two values of any type in ascending order.
///
/// - Parameters:
///   - lhs: The first value to compare.
///   - rhs: The second value to compare.
/// - Returns: A Boolean value indicating whether the first value is less than the second value.
func compareValuesAscending(_ lhs: Any, _ rhs: Any) -> Bool {
    switch (lhs, rhs) {
    case let (lhs as Bool, rhs as Bool):
        return !lhs && rhs
    case let (lhs as Int, rhs as Int):
        return lhs < rhs
    case let (lhs as Double, rhs as Double):
        return lhs < rhs
    case let (lhs as String, rhs as String):
        return lhs.caseInsensitiveCompare(rhs) == .orderedAscending
    case let (lhs as Date, rhs as Date):
        return lhs < rhs
    default:
        return String(describing: lhs) < String(describing: rhs)
    }
}
