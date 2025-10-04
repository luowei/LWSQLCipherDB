//
//  LWDBSQLState.swift
//  LWSQLCipherDB
//
//  Swift version of LWDBSQLState
//  Copyright © 2017 luowei. All rights reserved.
//  github http://wodedata.com

import Foundation

// MARK: - Query Type Enum

/// SQL query condition type
public enum QueryType: Int {
    case `where` = 0
    case and
    case or

    var stringValue: String {
        switch self {
        case .where:
            return "WHERE"
        case .and:
            return "AND"
        case .or:
            return "OR"
        }
    }
}

// MARK: - LWDBSQLState Class

/// SQL statement builder for query conditions
public class LWDBSQLState: NSObject {

    // MARK: - Properties

    /// Query type (WHERE, AND, OR)
    public var type: QueryType = .where

    /// Generated query string
    private var queryStr: String = ""

    // MARK: - Public Methods

    /// Build a query condition
    /// - Parameters:
    ///   - obj: Model class to query
    ///   - type: Query type (WHERE, AND, OR)
    ///   - key: Property key name
    ///   - opt: SQL operator (=, >, <, !=, etc.)
    ///   - value: Value to compare
    /// - Returns: Self for method chaining
    @discardableResult
    public func object(_ obj: AnyClass,
                      type: QueryType,
                      key: Any,
                      opt: String,
                      value: Any) -> LWDBSQLState {

        guard let modelClass = obj as? LWDBModel.Type else {
            return self
        }

        let model = modelClass.init()

        // Find the property and determine if it's TEXT type (needs quotes)
        if let keyString = key as? String {
            for i in 0..<model.propertyNames.count {
                if keyString == model.propertyNames[i] {
                    let columnName: String

                    // Check if property has a custom column name
                    if model.propertyNames[i] == model.columnNames[i] {
                        columnName = keyString
                    } else {
                        columnName = model.columnNames[i]
                    }

                    // Build query string based on column type
                    let columnType = model.columnTypes[i]
                    buildQueryString(
                        columnType: columnType,
                        key: columnName,
                        opt: opt,
                        value: value,
                        condition: type
                    )
                    break
                }
            }
        }

        return self
    }

    /// Get the generated SQL option string
    /// - Returns: SQL WHERE/AND/OR clause string
    public func sqlOptionStr() -> String {
        return queryStr
    }

    // MARK: - Private Methods

    /// Build query string based on column type
    private func buildQueryString(columnType: String,
                                  key: String,
                                  opt: String,
                                  value: Any,
                                  condition: QueryType) {

        let conditionStr = condition.stringValue

        // TEXT type needs quotes around value
        if columnType == SQLType.text {
            queryStr = " \(conditionStr) \(key) \(opt) '\(value)'"
        } else {
            queryStr = " \(conditionStr) \(key) \(opt) \(value)"
        }
    }
}
