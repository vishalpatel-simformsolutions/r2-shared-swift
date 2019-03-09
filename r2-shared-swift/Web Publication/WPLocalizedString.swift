//
//  WPLocalizedString.swift
//  r2-shared-swift
//
//  Created by Mickaël Menu on 09.03.19.
//
//  Copyright 2019 Readium Foundation. All rights reserved.
//  Use of this source code is governed by a BSD-style license which is detailed
//  in the LICENSE file present in the project repository where this source code is maintained.
//

import Foundation


/// Represents a localized string defined by this JSON schema:
///
///   "anyOf": [
///     {
///       "type": "string"
///     },
///     {
///       "description": "The language in a language map must be a valid BCP 47 tag.",
///       "type": "object",
///       "patternProperties": {
///         "^((?<grandfathered>(en-GB-oed|i-ami|i-bnn|i-default|i-enochian|i-hak|i-klingon|i-lux|i-mingo|i-navajo|i-pwn|i-tao|i-tay|i-tsu|sgn-BE-FR|sgn-BE-NL|sgn-CH-DE)|(art-lojban|cel-gaulish|no-bok|no-nyn|zh-guoyu|zh-hakka|zh-min|zh-min-nan|zh-xiang))|((?<language>([A-Za-z]{2,3}(-(?<extlang>[A-Za-z]{3}(-[A-Za-z]{3}){0,2}))?)|[A-Za-z]{4}|[A-Za-z]{5,8})(-(?<script>[A-Za-z]{4}))?(-(?<region>[A-Za-z]{2}|[0-9]{3}))?(-(?<variant>[A-Za-z0-9]{5,8}|[0-9][A-Za-z0-9]{3}))*(-(?<extension>[0-9A-WY-Za-wy-z](-[A-Za-z0-9]{2,8})+))*(-(?<privateUse>x(-[A-Za-z0-9]{1,8})+))?)|(?<privateUse2>x(-[A-Za-z0-9]{1,8})+))$": {
///           "type": "string"
///         }
///       },
///       "additionalProperties": false,
///       "minProperties": 1
///     }
///   ]
public enum WPLocalizedString: Equatable {
    case nonlocalized(String)
    case localized([String: String])
    
    /// Parses the given JSON representation of the localized string.
    public init?(json: Any?) throws {
        if json == nil {
            return nil
        } else if let string = json as? String {
            self = .nonlocalized(string)
        } else if let strings = json as? [String: String] {
            self = .localized(strings)
        } else {
            throw WPParsingError.localizedString
        }
    }
    
    /// Returns the JSON representation for this localized string.
    public var json: Any {
        switch self {
        case .nonlocalized(let string):
            return string
        case .localized(let strings):
            return strings
        }
    }

    /// Returns the localized string matching the most the user's locale.
    public var string: String {
        return string(forLanguageCode: nil)
    }
    
    /// Returns the localized string matching the given locale, or fallback on the user's locale.
    public func string(forLocale locale: Locale) -> String {
        return string(forLanguageCode: locale.languageCode)
    }
    
    /// Returns the localized string matching the given language code, or fallback on the user's locale.
    public func string(forLanguageCode languageCode: String?) -> String {
        switch self {
        case .nonlocalized(let string):
            return string
        case .localized(let strings):
            guard let languageCode = languageCode, let string = strings[languageCode] else {
                // Recovers using the user's preferred language in the available ones
                // See. https://developer.apple.com/library/archive/technotes/tn2418/_index.html
                let availableLanguages = Array(strings.keys)
                if let code = Bundle.preferredLocalizations(from: availableLanguages).first, let string = strings[code] {
                    return string
                }
                // According to the JSON schema, there's always at least one value. We fallback on an empty string just in case.
                return strings["en"] ?? strings.first?.value ?? ""
            }
            return string
        }
    }
    
}

extension WPLocalizedString: CustomStringConvertible {
    
    public var description: String {
        return string
    }
    
}

/// Syntactic sugar to create a localized string from a string literal.
/// This is useful when creating a struct that depends on one or several localized strings.
/// eg. let string: LocalizedString = "bonjour"
extension WPLocalizedString: ExpressibleByStringLiteral {
    public typealias StringLiteralType = String
    
    public init(stringLiteral value: StringLiteralType) {
        self = .nonlocalized(value)
    }
    
}

/// Syntactic sugar to create a localized string from a dictionary literal.
/// This is useful when creating a struct that depends on one or several localized strings.
/// eg. let string: LocalizedString = ["en": "hello"]
extension WPLocalizedString: ExpressibleByDictionaryLiteral {
    public typealias Key = String
    public typealias Value = String
    
    public init(dictionaryLiteral elements: (Key, Value)...) {
        self = .localized(Dictionary(uniqueKeysWithValues: elements))
    }
    
}
