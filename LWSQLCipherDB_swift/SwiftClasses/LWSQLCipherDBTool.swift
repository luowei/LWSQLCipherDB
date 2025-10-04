//
//  LWSQLCipherDBTool.swift
//  LWSQLCipherDB
//
//  Swift version of LWSQLCipherDBTool
//  Copyright © 2017 luowei. All rights reserved.
//  github http://wodedata.com

import Foundation

#if canImport(FMDB)
import FMDB
#endif

// MARK: - LWSQLCipherDBTool Class

/// Singleton database tool for managing SQLCipher encrypted databases
public class LWSQLCipherDBTool: NSObject {

    // MARK: - Properties

    /// Database queue for thread-safe operations
    public private(set) var dbQueue: FMDatabaseQueue?

    /// Secret key for database encryption (override in subclass or extension)
    open class var secretKey: String {
        return "luowei.wodedata.com"
    }

    // MARK: - Singleton

    /// Shared singleton instance
    public static let shared = LWSQLCipherDBTool()

    private override init() {
        super.init()
        // Initialize database queue on first access
        _ = self.dbQueue
    }

    // MARK: - Public Methods

    /// Get the default database path
    /// - Returns: Full path to the database file
    public class func dbPath() -> String {
        return dbPath(withDirectoryName: nil)
    }

    /// Get database path with custom directory name
    /// - Parameter directoryName: Custom directory name (optional)
    /// - Returns: Full path to the database file
    public class func dbPath(withDirectoryName directoryName: String?) -> String {
        let docsDir: String
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last!

        if let dirName = directoryName, !dirName.isEmpty {
            docsDir = (documentsPath as NSString).appendingPathComponent(dirName)
        } else {
            docsDir = (documentsPath as NSString).appendingPathComponent("LWDB")
        }

        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false
        let exists = fileManager.fileExists(atPath: docsDir, isDirectory: &isDirectory)

        if !exists || !isDirectory.boolValue {
            try? fileManager.createDirectory(
                atPath: docsDir,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }

        let dbPath = (docsDir as NSString).appendingPathComponent("lwdb")
        print("Database path: \(dbPath)")

        return dbPath
    }

    /// Change database to a different directory
    /// - Parameter directoryName: New directory name for the database
    /// - Returns: Success status
    @discardableResult
    public func changeDB(withDirectoryName directoryName: String?) -> Bool {
        // Close existing database queue
        if dbQueue != nil {
            dbQueue?.close()
            dbQueue = nil
        }

        // Create new database queue with new path
        let newPath = LWSQLCipherDBTool.dbPath(withDirectoryName: directoryName)
        dbQueue = FMDatabaseQueue(path: newPath)

        // Set encryption key
        dbQueue?.inDatabase { db in
            db.setKey(LWSQLCipherDBTool.secretKey)
        }

        // Recreate all tables for subclasses of LWDBModel
        recreateAllTables()

        return true
    }

    // MARK: - Private Methods

    /// Lazy initialization of database queue
    private func initializeDatabaseQueue() -> FMDatabaseQueue? {
        guard dbQueue == nil else {
            return dbQueue
        }

        let path = LWSQLCipherDBTool.dbPath()
        let queue = FMDatabaseQueue(path: path)

        // Set encryption key
        queue?.inDatabase { db in
            db.setKey(LWSQLCipherDBTool.secretKey)
        }

        return queue
    }

    /// Recreate all tables for LWDBModel subclasses
    private func recreateAllTables() {
        var classCount: UInt32 = 0
        guard let classList = objc_copyClassList(&classCount) else {
            return
        }

        for i in 0..<Int(classCount) {
            let currentClass: AnyClass = classList[i]

            // Check if this class is a subclass of LWDBModel
            if let modelClass = currentClass as? LWDBModel.Type,
               class_getSuperclass(currentClass) != nil {

                // Skip LWDBModel itself
                let className = NSStringFromClass(currentClass)
                if className != "LWDBModel" {
                    modelClass.createTable()
                }
            }
        }

        free(classList)
    }

    // MARK: - Computed Properties

    /// Access database queue (lazy initialization)
    private var _dbQueue: FMDatabaseQueue? {
        if dbQueue == nil {
            dbQueue = initializeDatabaseQueue()
        }
        return dbQueue
    }
}

// MARK: - Database Queue Access

extension LWSQLCipherDBTool {
    /// Safe access to database queue
    public var database: FMDatabaseQueue? {
        return _dbQueue
    }
}

// MARK: - FMDatabase Extension for Secret Key

#if canImport(FMDB)
extension FMDatabase {
    /// Set encryption key for the database
    /// - Parameter key: Encryption key string
    @objc public func setKey(_ key: String) {
        // Note: In Swift, we set the key directly
        // The original Objective-C version used method swizzling
        // In Swift, we override this method to set the encryption key
        if let keyData = key.data(using: .utf8) {
            self.setKey(keyData)
        }
    }
}
#endif
