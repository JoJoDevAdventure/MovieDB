//
//  Extensions.swift
//  Movie DB
//
//  Created by Jonas Frey on 18.11.19.
//  Copyright © 2019 Jonas Frey. All rights reserved.
//

import Foundation
import SwiftUI

extension KeyedDecodingContainer {
    /// Tries to decode a value with any of the given keys
    ///
    /// - Parameters:
    ///   - type: The type of the value to decode
    ///   - keys: The array of keys that the value may be associated with
    /// - Returns: The value associated with the first matching key that is not `nil`
    /// - Throws: `DecodingError.typeMismatch` if the encountered encoded value
    ///   is not convertible to the requested type.
    /// - Throws: `DecodingError.keyNotFound` if `self` does not have an non-nil entry
    ///   for any of the given keys.
    public func decodeAny<T>(_ type: T.Type, forKeys keys: [Self.Key]) throws -> T where T: Decodable {
        for key in keys {
            if let value = try decodeIfPresent(T.self, forKey: key) {
                return value
            }
        }
        let context = DecodingError.Context(
            codingPath: codingPath,
            debugDescription: "No value associated with any of the keys \(keys)"
        )
        throw DecodingError.keyNotFound(keys.first!, context)
    }
}

extension UnkeyedDecodingContainer {
    /// Tries to decode an array
    ///
    /// - Parameters:
    ///   - type: The type of the value to decode
    /// - Returns: The array of values associated with this unkeyed container
    /// - Throws: `DecodingError.typeMismatch` if the encountered encoded value
    ///   is not convertible to the requested type.
    public mutating func decodeArray<T>(_ type: T.Type) throws -> [T] where T: Decodable {
        var returnValues = [T]()
        
        while !self.isAtEnd {
            returnValues.append(try self.decode(T.self))
        }
        
        return returnValues
    }
}

extension Dictionary where Key == String, Value == Any? {
    /// Returns the dictionary as a string of HTTP arguments, percent escaped
    ///
    ///     [key1: "test", key2: "Hello World"].percentEscaped()
    ///     // Returns "key1=test&key2=Hello%20World"
    func percentEscaped() -> String {
        map { key, value in
            let escapedKey = key.addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? ""
            let escapedValue = "\(value ?? "null")"
                .addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? ""
            return escapedKey + "=" + escapedValue
        }
        .joined(separator: "&")
    }
}

extension CharacterSet {
    /// Returns the set of characters that are allowed in a URL query
    static let urlQueryValueAllowed: CharacterSet = {
        let generalDelimitersToEncode = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
        let subDelimitersToEncode = "!$&'()*+,;="
        
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "\(generalDelimitersToEncode)\(subDelimitersToEncode)")
        return allowed
    }()
}

extension Color {
    static let systemBackground = Color(UIColor.systemBackground)
}

extension NSSecureUnarchiveFromDataTransformer {
    static var name: NSValueTransformerName { .init(rawValue: String(describing: Self.self)) }
    
    static func register() {
        ValueTransformer.setValueTransformer(
            Self(),
            forName: Self.name
        )
    }
}
