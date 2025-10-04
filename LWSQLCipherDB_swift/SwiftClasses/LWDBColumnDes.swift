//
//  LWDBColumnDes.swift
//  LWSQLCipherDB
//
//  Swift version of LWDBColumnDes
//  Copyright © 2017 luowei. All rights reserved.
//  github http://wodedata.com

import Foundation

// MARK: - SQL Column Modifiers

/// Default value macro
public func DEFAULT(_ value: String) -> String {
    return "DEFAULT \(value)"
}

/// Check constraint macro
public func CHECK(_ value: String) -> String {
    return value
}

/// Foreign key macro
public func FOREIGNKEY(_ tableName: String, _ field: String) -> String {
    return "REFERENCES \(tableName) (\(field))"
}

// MARK: - LWDBColumnDes Class

/// Column description class for database field customization
public class LWDBColumnDes: NSObject {

    // MARK: - Properties

    /// Column alias/custom name
    public var columnName: String?

    /// Check constraint
    public var check: String?

    /// Default value
    public var defaultValue: String?

    /// Foreign key constraint
    public var foreignKey: String?

    /// Whether this is a primary key
    public var isPrimaryKey: Bool = false

    /// Whether this field is unique
    public var isUnique: Bool = false

    /// Whether this field cannot be null
    public var isNotNull: Bool = false

    /// Whether this field auto-increments (not applicable for TEXT types)
    public var isAutoincrement: Bool = false

    /// Whether to exclude this property from database field creation
    public var isUseless: Bool = false

    // MARK: - Initializers

    public override init() {
        super.init()
    }

    /// Primary key convenience initializer
    /// - Parameters:
    ///   - isAutoincrement: Whether to auto-increment
    ///   - notNull: Whether NOT NULL constraint applies
    ///   - check: Check constraint
    ///   - defaultValue: Default value
    public convenience init(autoincrement isAutoincrement: Bool,
                           notNull: Bool,
                           check: String? = nil,
                           defaultValue: String? = nil) {
        self.init()
        self.isPrimaryKey = true
        self.isAutoincrement = isAutoincrement
        self.isNotNull = notNull
        self.check = check
        self.defaultValue = defaultValue
    }

    /// General field convenience initializer
    /// - Parameters:
    ///   - isAutoincrement: Whether to auto-increment
    ///   - isUnique: Whether UNIQUE constraint applies
    ///   - notNull: Whether NOT NULL constraint applies
    ///   - check: Check constraint
    ///   - defaultValue: Default value
    public convenience init(autoincrement isAutoincrement: Bool,
                           unique isUnique: Bool,
                           notNull: Bool,
                           check: String? = nil,
                           defaultValue: String? = nil) {
        self.init()
        self.isAutoincrement = isAutoincrement
        self.isUnique = isUnique
        self.isNotNull = notNull
        self.check = check
        self.defaultValue = defaultValue
    }

    /// Foreign key field initializer
    /// - Parameters:
    ///   - isUnique: Whether UNIQUE constraint applies
    ///   - notNull: Whether NOT NULL constraint applies
    ///   - check: Check constraint
    ///   - defaultValue: Default value
    ///   - foreignKey: Foreign key constraint
    public convenience init(unique isUnique: Bool,
                           notNull: Bool,
                           check: String? = nil,
                           defaultValue: String? = nil,
                           foreignKey: String?) {
        self.init()
        self.isUnique = isUnique
        self.isNotNull = notNull
        self.check = check
        self.defaultValue = defaultValue
        self.foreignKey = foreignKey
    }

    // MARK: - Public Methods

    /// Check if a custom column name was set
    /// - Parameter attributeName: The attribute name to check
    /// - Returns: Whether the attribute name matches the custom column name
    public func isCustomColumnName(_ attributeName: String) -> Bool {
        return attributeName == columnName
    }

    /// Generate the complete SQL modifier string for this column
    /// - Returns: SQL modifier string
    public func finishModify() -> String {
        return customModify(
            isPrimaryKey: isPrimaryKey,
            isAutoincrement: isAutoincrement,
            isUnique: isUnique,
            isNotNull: isNotNull,
            check: check,
            defaultValue: defaultValue,
            foreignKey: foreignKey
        )
    }

    // MARK: - Private Methods

    /// Build custom modifier string with all constraints
    private func customModify(isPrimaryKey: Bool,
                             isAutoincrement: Bool,
                             isUnique: Bool,
                             isNotNull: Bool,
                             check: String?,
                             defaultValue: String?,
                             foreignKey: String?) -> String {
        var modify = ""

        modify += primaryKeyModifier(isPrimaryKey)
        modify += autoincrementModifier(isAutoincrement)
        modify += uniqueModifier(isUnique)
        modify += notNullModifier(isNotNull)
        modify += checkStringNull(defaultValue)
        modify += checkStringNull(foreignKey)

        // Remove trailing space if exists
        if modify.hasSuffix(" ") {
            modify.removeLast()
        }

        return modify
    }

    /// Generate primary key modifier
    private func primaryKeyModifier(_ value: Bool) -> String {
        return value ? "primary key " : ""
    }

    /// Generate autoincrement modifier
    private func autoincrementModifier(_ value: Bool) -> String {
        return value ? "AUTOINCREMENT " : ""
    }

    /// Generate unique modifier
    private func uniqueModifier(_ value: Bool) -> String {
        return value ? "UNIQUE " : ""
    }

    /// Generate NOT NULL modifier
    private func notNullModifier(_ value: Bool) -> String {
        return value ? "NOT NULL " : ""
    }

    /// Check if string is null/empty and format accordingly
    private func checkStringNull(_ str: String?) -> String {
        guard let str = str, !str.isEmpty else {
            return ""
        }
        return "\(str) "
    }

    // MARK: - Equatable

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? LWDBColumnDes else {
            return false
        }
        return other.columnName == self.columnName
    }
}
