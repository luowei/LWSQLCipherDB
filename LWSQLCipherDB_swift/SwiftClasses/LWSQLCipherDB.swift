//
//  LWSQLCipherDB.swift
//  LWSQLCipherDB
//
//  Main Swift module file for LWSQLCipherDB
//  Copyright © 2017 luowei. All rights reserved.
//  github http://wodedata.com

import Foundation

#if canImport(SwiftUI)
import SwiftUI
#endif

#if canImport(Combine)
import Combine
#endif

// MARK: - Module Information

/// LWSQLCipherDB - A wrapper around FMDB and SQLCipher for encrypted SQLite databases
/// This is the Swift/SwiftUI version of the library
public struct LWSQLCipherDB {
    public static let version = "1.0.0"
    public static let description = "Swift wrapper for FMDB and SQLCipher - Encrypted SQLite database"
}

// MARK: - SwiftUI Observable Model Wrapper

#if canImport(SwiftUI) && canImport(Combine)
/// Observable wrapper for LWDBModel to integrate with SwiftUI
@available(iOS 13.0, macOS 10.15, *)
open class ObservableLWDBModel: LWDBModel, ObservableObject {

    /// Published property that notifies observers when the model changes
    public let objectWillChange = PassthroughSubject<Void, Never>()

    /// Notify observers that the model will change
    public func notifyChange() {
        objectWillChange.send()
    }

    /// Save with change notification
    @discardableResult
    open override func save() -> Bool {
        objectWillChange.send()
        return super.save()
    }

    /// Update with change notification
    @discardableResult
    open override func update() -> Bool {
        objectWillChange.send()
        return super.update()
    }

    /// Save or update with change notification
    @discardableResult
    open override func saveOrUpdate() -> Bool {
        objectWillChange.send()
        return super.saveOrUpdate()
    }

    /// Delete with change notification
    @discardableResult
    open override func deleteObject() -> Bool {
        objectWillChange.send()
        return super.deleteObject()
    }
}
#endif

// MARK: - Database Configuration

/// Database configuration for customization
public struct LWDatabaseConfig {
    /// Custom database directory name
    public var directoryName: String?

    /// Custom encryption key (if nil, uses default)
    public var encryptionKey: String?

    /// Whether to enable verbose logging
    public var enableLogging: Bool = false

    public init(directoryName: String? = nil,
                encryptionKey: String? = nil,
                enableLogging: Bool = false) {
        self.directoryName = directoryName
        self.encryptionKey = encryptionKey
        self.enableLogging = enableLogging
    }
}

// MARK: - Database Manager (Convenience API)

/// High-level database manager for common operations
public class LWDatabaseManager {

    /// Shared instance
    public static let shared = LWDatabaseManager()

    private init() {}

    /// Configure database with custom settings
    /// - Parameter config: Database configuration
    public func configure(with config: LWDatabaseConfig) {
        if let directoryName = config.directoryName {
            LWSQLCipherDBTool.shared.changeDB(withDirectoryName: directoryName)
        }
    }

    /// Get database path
    /// - Returns: Full path to database file
    public func getDatabasePath() -> String {
        return LWSQLCipherDBTool.dbPath()
    }

    /// Check if a table exists
    /// - Parameter modelType: Model class type
    /// - Returns: True if table exists
    public func tableExists<T: LWDBModel>(for modelType: T.Type) -> Bool {
        return modelType.isExistInTable()
    }

    /// Create table for a model type
    /// - Parameter modelType: Model class type
    /// - Returns: Success status
    @discardableResult
    public func createTable<T: LWDBModel>(for modelType: T.Type) -> Bool {
        return modelType.createTable()
    }

    /// Clear all data from a table
    /// - Parameter modelType: Model class type
    /// - Returns: Success status
    @discardableResult
    public func clearTable<T: LWDBModel>(for modelType: T.Type) -> Bool {
        return modelType.clearTable()
    }

    /// Count records in a table
    /// - Parameter modelType: Model class type
    /// - Returns: Number of records
    public func count<T: LWDBModel>(for modelType: T.Type) -> Int {
        return modelType.findAll().count
    }
}

// MARK: - Query Builder (Fluent API)

/// Fluent query builder for database operations
public class LWQueryBuilder<T: LWDBModel> {

    private var criteria: String = ""
    private let modelType: T.Type

    public init(_ modelType: T.Type) {
        self.modelType = modelType
    }

    /// Add WHERE clause
    @discardableResult
    public func `where`(_ column: String, _ operator: String, _ value: Any) -> Self {
        let valueStr = formatValue(value)
        criteria += " WHERE \(column) \(operator) \(valueStr)"
        return self
    }

    /// Add AND clause
    @discardableResult
    public func and(_ column: String, _ operator: String, _ value: Any) -> Self {
        let valueStr = formatValue(value)
        criteria += " AND \(column) \(operator) \(valueStr)"
        return self
    }

    /// Add OR clause
    @discardableResult
    public func or(_ column: String, _ operator: String, _ value: Any) -> Self {
        let valueStr = formatValue(value)
        criteria += " OR \(column) \(operator) \(valueStr)"
        return self
    }

    /// Add ORDER BY clause
    @discardableResult
    public func orderBy(_ column: String, ascending: Bool = true) -> Self {
        let direction = ascending ? "ASC" : "DESC"
        criteria += " ORDER BY \(column) \(direction)"
        return self
    }

    /// Add LIMIT clause
    @discardableResult
    public func limit(_ count: Int) -> Self {
        criteria += " LIMIT \(count)"
        return self
    }

    /// Add OFFSET clause
    @discardableResult
    public func offset(_ count: Int) -> Self {
        criteria += " OFFSET \(count)"
        return self
    }

    /// Execute query and return results
    public func fetch() -> [T] {
        return modelType.find(byCriteria: criteria) as? [T] ?? []
    }

    /// Fetch first result
    public func fetchFirst() -> T? {
        return modelType.findFirst(byCriteria: criteria) as? T
    }

    /// Delete records matching criteria
    @discardableResult
    public func delete() -> Bool {
        return modelType.delete(byCriteria: criteria)
    }

    /// Get count of matching records
    public func count() -> Int {
        return fetch().count
    }

    /// Format value for SQL query
    private func formatValue(_ value: Any) -> String {
        if value is String {
            return "'\(value)'"
        } else {
            return "\(value)"
        }
    }
}

// MARK: - LWDBModel Extension for Query Builder

extension LWDBModel {
    /// Create a query builder for this model type
    public static func query<T: LWDBModel>() -> LWQueryBuilder<T> {
        return LWQueryBuilder(T.self)
    }
}

// MARK: - Async/Await Support (iOS 13+)

#if compiler(>=5.5) && canImport(_Concurrency)
@available(iOS 13.0, macOS 10.15, *)
extension LWDBModel {

    /// Async save operation
    public func saveAsync() async -> Bool {
        return await withCheckedContinuation { continuation in
            let result = self.save()
            continuation.resume(returning: result)
        }
    }

    /// Async update operation
    public func updateAsync() async -> Bool {
        return await withCheckedContinuation { continuation in
            let result = self.update()
            continuation.resume(returning: result)
        }
    }

    /// Async delete operation
    public func deleteAsync() async -> Bool {
        return await withCheckedContinuation { continuation in
            let result = self.deleteObject()
            continuation.resume(returning: result)
        }
    }

    /// Async find all operation
    public static func findAllAsync() async -> [LWDBModel] {
        return await withCheckedContinuation { continuation in
            let results = self.findAll()
            continuation.resume(returning: results)
        }
    }
}
#endif
