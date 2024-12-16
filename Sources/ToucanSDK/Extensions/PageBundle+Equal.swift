//
//  File.swift
//  toucan
//
//  Created by Viasz-Kádi Ferenc on 2024. 10. 17..
//

import Foundation

extension String {

    /// Converts the string into a value of the specified data type.
    ///
    /// - Parameters:
    ///   - dataType: The target data type to which the string should be converted.
    ///   - dateFormatter: The date formatter used to convert the string to a date if the data type is `date`.
    /// - Returns: The converted value of the specified type, or nil if the conversion fails.
//    func value<T>(
//        for dataType: ContentType.Property.DataType,
//        dateFormatter: DateFormatter
//    ) -> T? {
//        switch dataType {
//        case .bool:
//            return Bool(self) as? T
//        case .int:
//            return Int(self) as? T
//        case .double:
//            return Double(self) as? T
//        case .string:
//            return self as? T
//        case .date:
//            return dateFormatter.date(from: self) as? T
//        }
//    }
}

extension PageBundle {

    // TODO: should incloude defaultValue somehow?

    /// Checks if a filter is satisfied based on the current page's front matter.
    ///
    /// - Parameters:
    ///   - filter: The filter to check.
    ///   - dateFormatter: The date formatter used to parse date values.
    /// - Returns: A boolean indicating whether the filter is satisfied.
//    func checkFilter(
//        _ filter: ContentType.Filter,
//        dateFormatter: DateFormatter
//    ) -> Bool {
//        guard
//            let field = frontMatter[filter.field],
//            let dataType = contentType.properties?[filter.field]?.type,
//            let filterValue: Any = filter.value.value(
//                for: dataType,
//                dateFormatter: dateFormatter
//            )
//        else {
//            return false
//        }
//
//        switch filter.method {
//        case .equals:
//            return areValuesEqual(field, filterValue)
//        }
//    }
}

/// Compares two values of any type for equality.
///
/// - Parameters:
///   - lhs: The first value to compare.
///   - rhs: The second value to compare.
/// - Returns: A boolean indicating whether the two values are equal.
func areValuesEqual(_ lhs: Any, _ rhs: Any) -> Bool {
    switch (lhs, rhs) {
    case (let lhs as Bool, let rhs as Bool):
        return lhs == rhs
    case (let lhs as Int, let rhs as Int):
        return lhs == rhs
    case (let lhs as Double, let rhs as Double):
        return lhs == rhs
    case (let lhs as String, let rhs as String):
        return lhs == rhs
    case (let lhs as Date, let rhs as Date):
        return lhs == rhs
    case (let lhs as [Any], let rhs as [Any]):
        return lhs.elementsEqual(rhs, by: { areValuesEqual($0, $1) })
    case (let lhs as [String: Any], let rhs as [String: Any]):
        return lhs.isEqualTo(rhs)
    default:
        return false
    }
}

extension Dictionary where Key == String, Value == Any {

    /// Compares two dictionaries for equality by checking their keys and values.
    ///
    /// - Parameters:
    ///   - rhs: The dictionary to compare against.
    /// - Returns: A boolean indicating whether the two dictionaries are equal.
    func isEqualTo(_ rhs: [Key: Value]) -> Bool {
        guard self.count == rhs.count else { return false }
        for (key, value) in self {
            guard let rhsValue = rhs[key] else {
                return false
            }
            return areValuesEqual(value, rhsValue)
        }
        return true
    }
}
