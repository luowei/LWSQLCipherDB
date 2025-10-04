//
//  LWDBModel.swift
//  LWSQLCipherDB
//
//  Swift version of LWDBModel
//  Copyright © 2017 luowei. All rights reserved.
//  github http://wodedata.com

import Foundation

#if canImport(FMDB)
import FMDB
#endif

// MARK: - SQL Type Constants

public struct SQLType {
    public static let text = "TEXT"
    public static let integer = "INTEGER"
    public static let real = "REAL"
    public static let blob = "BLOB"
    public static let null = "NULL"
    public static let primaryKey = "primary key"
}

// MARK: - LWDBModel Base Class

/// Base model class for database operations with SQLCipher
open class LWDBModel: NSObject {

    // MARK: - Properties

    /// Row ID (primary key)
    @objc open var pk: Int = 0

    /// Property names from the class
    public private(set) var propertyNames: [String] = []

    /// Column types (TEXT, INTEGER, REAL, etc.)
    public private(set) var columnTypes: [String] = []

    /// Column names (may differ from property names if aliased)
    public private(set) var columnNames: [String] = []

    // MARK: - Initialization

    public override init() {
        super.init()
        let properties = type(of: self).getAllProperties()
        self.propertyNames = properties.names
        self.columnTypes = properties.types
        self.columnNames = type(of: self).getColumnNames()
    }

    // MARK: - Table Management

    /// Create table if it doesn't exist
    /// - Returns: Success status
    @discardableResult
    open class func createTable() -> Bool {
        var result = true

        guard let dbQueue = LWSQLCipherDBTool.shared.dbQueue else {
            return false
        }

        dbQueue.inTransaction { db, rollback in
            let tableName = String(describing: self)
            let columnAndType = self.getColumnAndTypeString()
            let sql = "CREATE TABLE IF NOT EXISTS \(tableName)(\(columnAndType));"

            if !db.executeUpdate(sql, withArgumentsIn: []) {
                result = false
                rollback.pointee = true
                return
            }

            // Get existing columns
            var existingColumns: [String] = []
            if let resultSet = db.getTableSchema(tableName) {
                while resultSet.next() {
                    if let column = resultSet.string(forColumn: "name") {
                        existingColumns.append(column)
                    }
                }
            }

            // Get all properties
            let properties = self.getAllProperties()
            let propertyColumns = self.getColumnNames()

            // Find columns that need to be added
            let columnsToAdd = propertyColumns.filter { !existingColumns.contains($0) }

            // Add new columns
            for column in columnsToAdd {
                if let index = propertyColumns.firstIndex(of: column) {
                    let propertyType = properties.types[index]
                    let fieldSql = "\(column) \(propertyType)"
                    let alterSql = "ALTER TABLE \(tableName) ADD COLUMN \(fieldSql)"

                    if !db.executeUpdate(alterSql, withArgumentsIn: []) {
                        result = false
                        rollback.pointee = true
                        return
                    }
                }
            }
        }

        return result
    }

    /// Check if table exists in database
    /// - Returns: True if table exists
    open class func isExistInTable() -> Bool {
        var exists = false

        guard let dbQueue = LWSQLCipherDBTool.shared.dbQueue else {
            return false
        }

        dbQueue.inDatabase { db in
            let tableName = String(describing: self)
            exists = db.tableExists(tableName)
        }

        return exists
    }

    /// Get all columns from the table
    /// - Returns: Array of column names
    open class func getColumns() -> [String] {
        var columns: [String] = []

        guard let dbQueue = LWSQLCipherDBTool.shared.dbQueue else {
            return columns
        }

        dbQueue.inDatabase { db in
            let tableName = String(describing: self)
            if let resultSet = db.getTableSchema(tableName) {
                while resultSet.next() {
                    if let column = resultSet.string(forColumn: "name") {
                        columns.append(column)
                    }
                }
            }
        }

        return columns
    }

    // MARK: - CRUD Operations - Save

    /// Save or update the record
    /// - Returns: Success status
    @discardableResult
    open func saveOrUpdate() -> Bool {
        let pkInfo = type(of: self).getPKName()
        guard let pkProperty = pkInfo.pkProperty,
              let primaryValue = value(forKey: pkProperty) else {
            return save()
        }

        if let model = type(of: self).findByPK(primaryValue) {
            let dbPKValue = model.value(forKey: pkProperty)
            if let dbValue = dbPKValue, isEqual(primaryValue, dbValue) {
                return update()
            }
        }

        return save()
    }

    /// Save or update by specific column
    @discardableResult
    open func saveOrUpdate(byColumnName columnName: String, columnValue: String) -> Bool {
        let criteria = "WHERE \(columnName) = \(columnValue)"

        if let record = type(of: self).findFirst(byCriteria: criteria) {
            let pkInfo = type(of: self).getPKName()
            if let pkProperty = pkInfo.pkProperty,
               let primaryValue = record.value(forKey: pkProperty) as? Int,
               primaryValue > 0 {
                self.pk = primaryValue
                return update()
            }
        }

        return save()
    }

    /// Save a single record
    /// - Returns: Success status
    @discardableResult
    open func save() -> Bool {
        let tableName = String(describing: type(of: self))
        var keyString = ""
        var valueString = ""
        var insertValues: [Any] = []

        for i in 0..<columnNames.count {
            let columnName = columnNames[i]
            keyString += "\(columnName),"
            valueString += "?,"

            let propertyValue = value(forKey: propertyNames[i]) ?? ""
            insertValues.append(propertyValue)
        }

        // Remove trailing commas
        keyString = String(keyString.dropLast())
        valueString = String(valueString.dropLast())

        var result = false

        guard let dbQueue = LWSQLCipherDBTool.shared.dbQueue else {
            return false
        }

        dbQueue.inDatabase { db in
            let sql = "INSERT INTO \(tableName)(\(keyString)) VALUES (\(valueString));"
            result = db.executeUpdate(sql, withArgumentsIn: insertValues)

            if result {
                self.pk = Int(db.lastInsertRowId)
                print("Insert succeeded")
            } else {
                print("Insert failed")
            }
        }

        return result
    }

    /// Save multiple records
    /// - Parameter array: Array of LWDBModel objects
    /// - Returns: Success status
    @discardableResult
    open class func save(objects array: [LWDBModel]) -> Bool {
        // Validate all objects are LWDBModel instances
        for model in array {
            if !(model is LWDBModel) {
                return false
            }
        }

        var result = true

        guard let dbQueue = LWSQLCipherDBTool.shared.dbQueue else {
            return false
        }

        dbQueue.inTransaction { db, rollback in
            for model in array {
                let tableName = String(describing: type(of: model))
                var keyString = ""
                var valueString = ""
                var insertValues: [Any] = []

                for i in 0..<model.columnNames.count {
                    let columnName = model.columnNames[i]
                    keyString += "\(columnName),"
                    valueString += "?,"

                    let properties = type(of: model).getAllProperties()
                    let propertyValue = model.value(forKey: properties.names[i]) ?? ""
                    insertValues.append(propertyValue)
                }

                keyString = String(keyString.dropLast())
                valueString = String(valueString.dropLast())

                let sql = "INSERT INTO \(tableName)(\(keyString)) VALUES (\(valueString));"
                let flag = db.executeUpdate(sql, withArgumentsIn: insertValues)

                if flag {
                    model.pk = Int(db.lastInsertRowId)
                    print("Insert succeeded")
                } else {
                    print("Insert failed")
                    result = false
                    rollback.pointee = true
                    return
                }
            }
        }

        return result
    }

    /// Save or update multiple records
    @discardableResult
    open class func saveOrUpdate(objects array: [LWDBModel]) -> Bool {
        var allSuccess = true
        for model in array {
            if !model.saveOrUpdate() {
                allSuccess = false
            }
        }
        return allSuccess
    }

    // MARK: - CRUD Operations - Update

    /// Update a single record
    /// - Returns: Success status
    @discardableResult
    open func update() -> Bool {
        var result = false

        guard let dbQueue = LWSQLCipherDBTool.shared.dbQueue else {
            return false
        }

        dbQueue.inDatabase { db in
            let tableName = String(describing: type(of: self))
            let pkInfo = type(of: self).getPKName()

            guard let pkProperty = pkInfo.pkProperty,
                  let pkColumn = pkInfo.pkColumn,
                  let primaryValue = self.value(forKey: pkProperty) else {
                return
            }

            var keyString = ""
            var updateValues: [Any] = []

            for i in 0..<self.columnNames.count {
                let columnName = self.columnNames[i]
                keyString += " \(columnName)=?,"

                let propertyValue = self.value(forKey: self.propertyNames[i]) ?? ""
                updateValues.append(propertyValue)
            }

            keyString = String(keyString.dropLast())

            let sql = "UPDATE \(tableName) SET \(keyString) WHERE \(pkColumn) = ?;"
            updateValues.append(primaryValue)

            result = db.executeUpdate(sql, withArgumentsIn: updateValues)
            print(result ? "Update succeeded" : "Update failed")
        }

        return result
    }

    /// Update multiple records
    @discardableResult
    open class func update(objects array: [LWDBModel]) -> Bool {
        for model in array {
            if !(model is LWDBModel) {
                return false
            }
        }

        var result = true

        guard let dbQueue = LWSQLCipherDBTool.shared.dbQueue else {
            return false
        }

        dbQueue.inTransaction { db, rollback in
            for model in array {
                let tableName = String(describing: type(of: model))
                let pkInfo = type(of: model).getPKName()

                guard let pkProperty = pkInfo.pkProperty,
                      let pkColumn = pkInfo.pkColumn,
                      let primaryValue = model.value(forKey: pkProperty) else {
                    result = false
                    rollback.pointee = true
                    return
                }

                var keyString = ""
                var updateValues: [Any] = []

                for i in 0..<model.columnNames.count {
                    let columnName = model.columnNames[i]
                    keyString += " \(columnName)=?,"

                    let properties = type(of: model).getAllProperties()
                    let propertyValue = model.value(forKey: properties.names[i]) ?? ""
                    updateValues.append(propertyValue)
                }

                keyString = String(keyString.dropLast())

                let sql = "UPDATE \(tableName) SET \(keyString) WHERE \(pkColumn)=?;"
                updateValues.append(primaryValue)

                let flag = db.executeUpdate(sql, withArgumentsIn: updateValues)
                print(flag ? "Update succeeded" : "Update failed")

                if !flag {
                    result = false
                    rollback.pointee = true
                    return
                }
            }
        }

        return result
    }

    // MARK: - CRUD Operations - Delete

    /// Delete this record
    /// - Returns: Success status
    @discardableResult
    open func deleteObject() -> Bool {
        var result = false

        guard let dbQueue = LWSQLCipherDBTool.shared.dbQueue else {
            return false
        }

        dbQueue.inDatabase { db in
            let tableName = String(describing: type(of: self))
            let pkInfo = type(of: self).getPKName()

            guard let pkProperty = pkInfo.pkProperty,
                  let pkColumn = pkInfo.pkColumn,
                  let primaryValue = self.value(forKey: pkProperty) else {
                return
            }

            let sql = "DELETE FROM \(tableName) WHERE \(pkColumn) = ?"
            result = db.executeUpdate(sql, withArgumentsIn: [primaryValue])
            print(result ? "Delete succeeded" : "Delete failed")
        }

        return result
    }

    /// Delete multiple records
    @discardableResult
    open class func delete(objects array: [LWDBModel]) -> Bool {
        for model in array {
            if !(model is LWDBModel) {
                return false
            }
        }

        var result = true

        guard let dbQueue = LWSQLCipherDBTool.shared.dbQueue else {
            return false
        }

        dbQueue.inTransaction { db, rollback in
            for model in array {
                let tableName = String(describing: type(of: model))
                let pkInfo = type(of: model).getPKName()

                guard let pkProperty = pkInfo.pkProperty,
                      let pkColumn = pkInfo.pkColumn,
                      let primaryValue = model.value(forKey: pkProperty) else {
                    continue
                }

                let sql = "DELETE FROM \(tableName) WHERE \(pkColumn) = ?"
                let flag = db.executeUpdate(sql, withArgumentsIn: [primaryValue])
                print(flag ? "Delete succeeded" : "Delete failed")

                if !flag {
                    result = false
                    rollback.pointee = true
                    return
                }
            }
        }

        return result
    }

    /// Delete records by criteria
    @discardableResult
    open class func delete(byCriteria criteria: String) -> Bool {
        var result = false

        guard let dbQueue = LWSQLCipherDBTool.shared.dbQueue else {
            return false
        }

        dbQueue.inDatabase { db in
            let tableName = String(describing: self)
            let sql = "DELETE FROM \(tableName) \(criteria)"
            result = db.executeUpdate(sql, withArgumentsIn: [])
            print(result ? "Delete succeeded" : "Delete failed")
        }

        return result
    }

    /// Delete records with format string
    @discardableResult
    open class func delete(withFormat format: String, _ arguments: CVarArg...) -> Bool {
        let criteria = String(format: format, arguments: arguments)
        return delete(byCriteria: criteria)
    }

    /// Clear all records from table
    @discardableResult
    open class func clearTable() -> Bool {
        var result = false

        guard let dbQueue = LWSQLCipherDBTool.shared.dbQueue else {
            return false
        }

        dbQueue.inDatabase { db in
            let tableName = String(describing: self)
            let sql = "DELETE FROM \(tableName)"
            result = db.executeUpdate(sql, withArgumentsIn: [])
            print(result ? "Clear succeeded" : "Clear failed")
        }

        return result
    }

    // MARK: - CRUD Operations - Find/Query

    /// Find all records
    /// - Returns: Array of model instances
    open class func findAll() -> [LWDBModel] {
        var results: [LWDBModel] = []

        guard let dbQueue = LWSQLCipherDBTool.shared.dbQueue else {
            return results
        }

        dbQueue.inDatabase { db in
            let tableName = String(describing: self)
            let sql = "SELECT * FROM \(tableName)"

            if let resultSet = db.executeQuery(sql, withArgumentsIn: []) {
                while resultSet.next() {
                    if let model = parseModel(from: resultSet) {
                        results.append(model)
                    }
                }
            }
        }

        return results
    }

    /// Find record by primary key
    open class func findByPK(_ pk: Any) -> LWDBModel? {
        let pkInfo = getPKName()
        guard let pkColumn = pkInfo.pkColumn else {
            return nil
        }

        let properties = getAllProperties()
        var condition = "WHERE \(pkColumn) = \(pk)"

        // Add quotes for TEXT type
        if let firstType = properties.types.first, firstType == SQLType.text {
            condition = "WHERE \(pkColumn) = '\(pk)'"
        }

        return findFirst(byCriteria: condition)
    }

    /// Find first record matching criteria
    open class func findFirst(byCriteria criteria: String) -> LWDBModel? {
        let results = find(byCriteria: criteria)
        return results.first
    }

    /// Find first record with format string
    open class func findFirst(withFormat format: String, _ arguments: CVarArg...) -> LWDBModel? {
        let criteria = String(format: format, arguments: arguments)
        return findFirst(byCriteria: criteria)
    }

    /// Find records matching criteria
    open class func find(byCriteria criteria: String) -> [LWDBModel] {
        var results: [LWDBModel] = []

        guard let dbQueue = LWSQLCipherDBTool.shared.dbQueue else {
            return results
        }

        dbQueue.inDatabase { db in
            let tableName = String(describing: self)
            let sql = "SELECT * FROM \(tableName) \(criteria)"

            if let resultSet = db.executeQuery(sql, withArgumentsIn: []) {
                while resultSet.next() {
                    if let model = parseModel(from: resultSet) {
                        results.append(model)
                    }
                }
            }
        }

        return results
    }

    /// Find records with format string
    open class func find(withFormat format: String, _ arguments: CVarArg...) -> [LWDBModel] {
        let criteria = String(format: format, arguments: arguments)
        return find(byCriteria: criteria)
    }

    // MARK: - Helper Methods

    /// Parse model from result set
    private class func parseModel(from resultSet: FMResultSet) -> LWDBModel? {
        let model = self.init()

        for i in 0..<model.columnNames.count {
            let columnName = model.columnNames[i]
            let columnType = model.columnTypes[i]
            let propertyName = model.propertyNames[i]

            if columnType == SQLType.text {
                let value = resultSet.string(forColumn: columnName) ?? ""
                model.setValue(value, forKey: propertyName)
            } else {
                let value = resultSet.longLongInt(forColumn: columnName)
                model.setValue(NSNumber(value: value), forKey: propertyName)
            }
        }

        return model
    }

    /// Check if two values are equal
    private func isEqual(_ value1: Any, _ value2: Any) -> Bool {
        return "\(value1)" == "\(value2)"
    }

    // MARK: - Property Reflection

    /// Get all properties from the class
    open class func getProperties() -> (names: [String], types: [String]) {
        var propertyNames: [String] = []
        var propertyTypes: [String] = []
        let transients = self.transients()

        var count: UInt32 = 0
        guard let properties = class_copyPropertyList(self, &count) else {
            return ([], [])
        }

        for i in 0..<Int(count) {
            let property = properties[i]
            guard let propertyName = String(utf8String: property_getName(property)) else {
                continue
            }

            // Skip transient properties
            if transients.contains(propertyName) {
                continue
            }

            propertyNames.append(propertyName)

            // Get property type
            guard let attributes = String(utf8String: property_getAttributes(property)) else {
                propertyTypes.append(SQLType.text)
                continue
            }

            // Parse type from attributes
            if attributes.hasPrefix("T@") {
                propertyTypes.append(SQLType.text)
            } else if attributes.hasPrefix("Ti") || attributes.hasPrefix("TI") ||
                      attributes.hasPrefix("Ts") || attributes.hasPrefix("TS") ||
                      attributes.hasPrefix("TB") || attributes.hasPrefix("Tq") ||
                      attributes.hasPrefix("TQ") {
                propertyTypes.append(SQLType.integer)
            } else {
                propertyTypes.append(SQLType.real)
            }
        }

        free(properties)

        return (propertyNames, propertyTypes)
    }

    /// Get all properties including primary key
    open class func getAllProperties() -> (names: [String], types: [String]) {
        return getProperties()
    }

    /// Get transient properties (properties that should not be saved to DB)
    open class func transients() -> [String] {
        var transients: [String] = []

        let columnDict = describeColumnDict()
        for (key, value) in columnDict {
            if value.isUseless {
                transients.append(key)
            }
        }

        return transients
    }

    /// Get column names (with custom aliases applied)
    open class func getColumnNames() -> [String] {
        var customNames: [String: String] = [:]
        let columnDict = describeColumnDict()

        for (key, value) in columnDict {
            if let columnName = value.columnName, !value.isCustomColumnName(key) {
                customNames[key] = columnName
            }
        }

        let properties = getProperties()
        var columnNames = properties.names

        for i in 0..<columnNames.count {
            if let customName = customNames[columnNames[i]] {
                columnNames[i] = customName
            }
        }

        return columnNames
    }

    /// Get primary key information
    open class func getPKName() -> (pkProperty: String?, pkColumn: String?) {
        var pkProperty: String?
        var pkColumn: String?

        let columnDict = describeColumnDict()
        for (key, value) in columnDict {
            if value.isPrimaryKey {
                pkProperty = key

                if let columnName = value.columnName, !value.isCustomColumnName(key) {
                    pkColumn = columnName
                } else {
                    pkColumn = key
                }

                break
            }
        }

        return (pkProperty, pkColumn)
    }

    /// Get column and type string for CREATE TABLE
    open class func getColumnAndTypeString() -> String {
        var result = ""
        let properties = getAllProperties()
        let columns = getColumnNames()
        let modifiers = getPKAndColumnModifiers()

        for i in 0..<columns.count {
            result += "\(columns[i]) \(properties.types[i]) \(modifiers[i])"
            if i + 1 != columns.count {
                result += ","
            }
        }

        return result
    }

    /// Get primary key and column modifiers
    open class func getPKAndColumnModifiers() -> [String] {
        var modifiers: [String] = []
        let properties = getAllProperties()
        let columnDict = describeColumnDict()

        for propertyName in properties.names {
            if let columnDes = columnDict[propertyName] {
                modifiers.append(columnDes.finishModify())
            } else {
                modifiers.append("")
            }
        }

        return modifiers
    }

    // MARK: - Override Methods

    /// Describe column dictionary - override in subclass to customize columns
    /// - Returns: Dictionary mapping property names to LWDBColumnDes objects
    open class func describeColumnDict() -> [String: LWDBColumnDes] {
        return [:]
    }

    // MARK: - Description

    open override var description: String {
        var result = ""
        let properties = type(of: self).getAllProperties()

        for propertyName in properties.names {
            let value = self.value(forKey: propertyName) ?? "nil"
            result += "\(propertyName): \(value)\n"
        }

        return result
    }
}
