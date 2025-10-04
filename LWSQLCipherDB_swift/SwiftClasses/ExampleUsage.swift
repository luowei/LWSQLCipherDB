//
//  ExampleUsage.swift
//  LWSQLCipherDB
//
//  Example usage of the Swift version of LWSQLCipherDB
//  Copyright © 2017 luowei. All rights reserved.
//

import Foundation

#if canImport(SwiftUI)
import SwiftUI
#endif

// MARK: - Example Model Definition

/// Example User model
class User: LWDBModel {

    @objc var userId: Int = 0
    @objc var username: String = ""
    @objc var email: String = ""
    @objc var age: Int = 0
    @objc var createdAt: String = ""

    /// Configure column descriptions
    override class func describeColumnDict() -> [String: LWDBColumnDes] {
        var dict: [String: LWDBColumnDes] = [:]

        // Define userId as primary key with auto-increment
        let userIdColumn = LWDBColumnDes(autoincrement: true, notNull: true)
        userIdColumn.isPrimaryKey = true
        dict["userId"] = userIdColumn

        // Username must be unique and not null
        let usernameColumn = LWDBColumnDes(autoincrement: false, unique: true, notNull: true)
        dict["username"] = usernameColumn

        // Email is optional but should be unique if provided
        let emailColumn = LWDBColumnDes(autoincrement: false, unique: true, notNull: false)
        dict["email"] = emailColumn

        return dict
    }
}

// MARK: - Basic CRUD Examples

class DatabaseExamples {

    /// Example: Create and save a user
    static func createUserExample() {
        let user = User()
        user.username = "john_doe"
        user.email = "john@example.com"
        user.age = 25
        user.createdAt = "\(Date())"

        if user.save() {
            print("User saved successfully with ID: \(user.pk)")
        }
    }

    /// Example: Find all users
    static func findAllUsersExample() {
        let users = User.findAll() as? [User] ?? []
        print("Found \(users.count) users")

        for user in users {
            print("User: \(user.username), Age: \(user.age)")
        }
    }

    /// Example: Find user by ID
    static func findUserByIdExample() {
        if let user = User.findByPK(1) as? User {
            print("Found user: \(user.username)")
        }
    }

    /// Example: Update a user
    static func updateUserExample() {
        if let user = User.findByPK(1) as? User {
            user.age = 26
            if user.update() {
                print("User updated successfully")
            }
        }
    }

    /// Example: Delete a user
    static func deleteUserExample() {
        if let user = User.findByPK(1) as? User {
            if user.deleteObject() {
                print("User deleted successfully")
            }
        }
    }

    /// Example: Query with criteria
    static func queryWithCriteriaExample() {
        // Find users older than 18
        let adults = User.find(byCriteria: "WHERE age > 18") as? [User] ?? []
        print("Found \(adults.count) adult users")

        // Find users with specific username
        if let user = User.findFirst(byCriteria: "WHERE username = 'john_doe'") as? User {
            print("Found user: \(user.email)")
        }
    }

    /// Example: Batch operations
    static func batchOperationsExample() {
        var users: [User] = []

        for i in 1...10 {
            let user = User()
            user.username = "user\(i)"
            user.email = "user\(i)@example.com"
            user.age = 20 + i
            users.append(user)
        }

        // Save all users in a transaction
        if User.save(objects: users) {
            print("All users saved successfully")
        }
    }

    /// Example: Using query builder (Fluent API)
    static func queryBuilderExample() {
        // Find users older than 18, ordered by age, limit 10
        let query: LWQueryBuilder<User> = User.query()
        let results = query
            .where("age", ">", 18)
            .orderBy("age", ascending: false)
            .limit(10)
            .fetch()

        print("Found \(results.count) users")
    }

    /// Example: Custom database configuration
    static func customConfigExample() {
        let config = LWDatabaseConfig(
            directoryName: "MyApp",
            enableLogging: true
        )

        LWDatabaseManager.shared.configure(with: config)
        print("Database path: \(LWDatabaseManager.shared.getDatabasePath())")
    }

    /// Example: Clear table
    static func clearTableExample() {
        if User.clearTable() {
            print("User table cleared")
        }
    }
}

// MARK: - SwiftUI Integration Example

#if canImport(SwiftUI)
@available(iOS 13.0, macOS 10.15, *)
class ObservableUser: ObservableLWDBModel {

    @objc dynamic var userId: Int = 0
    @objc dynamic var username: String = ""
    @objc dynamic var email: String = ""
    @objc dynamic var age: Int = 0

    override class func describeColumnDict() -> [String: LWDBColumnDes] {
        var dict: [String: LWDBColumnDes] = [:]

        let userIdColumn = LWDBColumnDes(autoincrement: true, notNull: true)
        userIdColumn.isPrimaryKey = true
        dict["userId"] = userIdColumn

        return dict
    }
}

@available(iOS 13.0, macOS 10.15, *)
struct UserListView: View {
    @State private var users: [ObservableUser] = []

    var body: some View {
        List(users, id: \.userId) { user in
            VStack(alignment: .leading) {
                Text(user.username)
                    .font(.headline)
                Text(user.email)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .onAppear {
            loadUsers()
        }
    }

    private func loadUsers() {
        users = ObservableUser.findAll() as? [ObservableUser] ?? []
    }
}

@available(iOS 13.0, macOS 10.15, *)
struct UserDetailView: View {
    @ObservedObject var user: ObservableUser

    var body: some View {
        Form {
            TextField("Username", text: $user.username)
            TextField("Email", text: $user.email)

            Button("Save") {
                user.saveOrUpdate()
            }
        }
    }
}
#endif

// MARK: - Async/Await Example

#if compiler(>=5.5) && canImport(_Concurrency)
@available(iOS 13.0, macOS 10.15, *)
class AsyncDatabaseExamples {

    /// Example: Async save operation
    static func asyncSaveExample() async {
        let user = User()
        user.username = "async_user"
        user.email = "async@example.com"
        user.age = 30

        let success = await user.saveAsync()
        if success {
            print("User saved asynchronously")
        }
    }

    /// Example: Async find operation
    static func asyncFindExample() async {
        let users = await User.findAllAsync()
        print("Found \(users.count) users asynchronously")
    }

    /// Example: Async update operation
    static func asyncUpdateExample() async {
        if let user = User.findByPK(1) as? User {
            user.age = 31
            let success = await user.updateAsync()
            if success {
                print("User updated asynchronously")
            }
        }
    }
}
#endif

// MARK: - Advanced Usage Examples

class AdvancedExamples {

    /// Example: Custom column names
    class Product: LWDBModel {
        @objc var productId: Int = 0
        @objc var productName: String = ""
        @objc var price: Double = 0.0

        override class func describeColumnDict() -> [String: LWDBColumnDes] {
            var dict: [String: LWDBColumnDes] = [:]

            // Primary key
            let idColumn = LWDBColumnDes(autoincrement: true, notNull: true)
            idColumn.isPrimaryKey = true
            dict["productId"] = idColumn

            // Custom column name
            let nameColumn = LWDBColumnDes()
            nameColumn.columnName = "prod_name"  // Different from property name
            dict["productName"] = nameColumn

            return dict
        }
    }

    /// Example: Excluding properties from database
    class CachedUser: LWDBModel {
        @objc var userId: Int = 0
        @objc var username: String = ""
        @objc var cachedData: String = ""  // This won't be saved to DB

        override class func describeColumnDict() -> [String: LWDBColumnDes] {
            var dict: [String: LWDBColumnDes] = [:]

            let idColumn = LWDBColumnDes(autoincrement: true, notNull: true)
            idColumn.isPrimaryKey = true
            dict["userId"] = idColumn

            // Mark cachedData as useless (won't create DB column)
            let cacheColumn = LWDBColumnDes()
            cacheColumn.isUseless = true
            dict["cachedData"] = cacheColumn

            return dict
        }
    }

    /// Example: Complex queries
    static func complexQueryExample() {
        // Using SQL state builder
        let sqlState = LWDBSQLState()
        sqlState.object(User.self, type: .where, key: "age", opt: ">", value: 18)

        let condition = sqlState.sqlOptionStr()
        let users = User.find(byCriteria: condition) as? [User] ?? []
        print("Found \(users.count) users with complex query")
    }

    /// Example: Transaction-like batch operations
    static func transactionExample() {
        var users: [User] = []

        for i in 1...100 {
            let user = User()
            user.username = "batch_user_\(i)"
            user.email = "batch\(i)@example.com"
            users.append(user)
        }

        // All saves happen in a transaction - all succeed or all fail
        if User.save(objects: users) {
            print("All 100 users saved in transaction")
        } else {
            print("Transaction failed - no users saved")
        }
    }
}
