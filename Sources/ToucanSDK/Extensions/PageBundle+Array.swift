//
//  File.swift
//  toucan
//
//  Created by Viasz-Kádi Ferenc on 2024. 10. 17..
//

import Foundation
import Yams

extension [PageBundle] {

    /// Sorts an array of PageBundle objects based on the given key and order.
    ///
    /// - Parameters:
    ///   - key: The key used for sorting the PageBundle objects.
    ///   - order: The order in which the sorting should be done (e.g., ascending or descending).
    ///
    /// - Returns: A sorted array of PageBundle objects, or the original array if key or order is nil.
//    func sorted(
//        frontMatterKey: String?,
//        order: ContentType.Order?
//    ) -> [PageBundle] {
//        guard
//            let frontMatterKey,
//            let order
//        else {
//            return self
//        }
//        return sorted { lhs, rhs in
//            lhs.compareForSorting(
//                for: rhs,
//                frontMatterKey: frontMatterKey,
//                order: order
//            )
//        }
//    }

    /// Limits the number of elements in the collection to the specified value if provided.
    /// If no value is provided, returns the entire collection.
    ///
    /// - Parameters:
    ///   - value: An optional integer specifying the maximum number of elements to return.
    ///
    /// - Returns: An array containing up to the specified number of elements, or the entire collection if no value is provided.
    func limited(_ value: Int?) -> [PageBundle] {
        guard let value else {
            return self
        }
        return Array(prefix(value))
    }

    /// Filters an array of `PageBundle` objects based on the provided filter and date formatter.
    ///
    /// - Parameters:
    ///   - filter: An optional `ContentType.Filter` to apply. If `nil`, the original array is returned.
    ///   - dateFormatter: A `DateFormatter` used for date-based filtering.
    ///
    /// - Returns: A filtered array of `PageBundle` objects. If no filter is provided, the original array is returned.
//    func filtered(
//        _ filter: ContentType.Filter?,
//        dateFormatter: DateFormatter
//    ) -> [PageBundle] {
//        guard let filter else {
//            return self
//        }
//
//        let result = self.filter {
//            $0.checkFilter(filter, dateFormatter: dateFormatter)
//        }
//        return result
//    }
}
