# LWSQLCipherDB - Swift/SwiftUI Version

Swift implementation of LWSQLCipherDB, a wrapper around FMDB and SQLCipher for encrypted SQLite databases on iOS.

## Overview

This is a modern Swift port of the original Objective-C LWSQLCipherDB library, featuring:

- **Pure Swift implementation** with SwiftUI support
- **Type-safe** database operations
- **Encrypted database** using SQLCipher
- **Observable models** for SwiftUI integration
- **Fluent query builder** API
- **Async/await** support (iOS 13+)
- **Protocol-oriented** design
- **Thread-safe** operations via FMDatabaseQueue

## Files

### Core Files

1. **LWDBModel.swift** (810 lines)
   - Base model class for all database entities
   - Provides CRUD operations (Create, Read, Update, Delete)
   - Automatic table creation and schema migration
   - Property reflection and type mapping
   - Transaction support for batch operations

2. **LWSQLCipherDBTool.swift** (185 lines)
   - Singleton database manager
   - Database encryption key management
   - Database path configuration
   - Thread-safe database queue management

3. **LWDBColumnDes.swift** (212 lines)
   - Column description and customization
   - Support for primary keys, unique constraints, NOT NULL, auto-increment
   - Custom column naming (aliases)
   - Foreign key support

4. **LWDBSQLState.swift** (121 lines)
   - SQL query condition builder
   - WHERE, AND, OR clause support
   - Automatic type handling (TEXT vs INTEGER)

5. **LWSQLCipherDB.swift** (286 lines)
   - Main module file
   - SwiftUI observable model wrapper
   - Database configuration
   - High-level database manager
   - Fluent query builder API
   - Async/await extensions

6. **ExampleUsage.swift** (341 lines)
   - Comprehensive usage examples
   - Model definition examples
   - CRUD operation examples
   - SwiftUI integration examples
   - Async/await examples
   - Advanced usage patterns

## Key Features

### 1. Simple Model Definition

```swift
class User: LWDBModel {
    @objc var userId: Int = 0
    @objc var username: String = ""
    @objc var email: String = ""
    @objc var age: Int = 0

    override class func describeColumnDict() -> [String: LWDBColumnDes] {
        var dict: [String: LWDBColumnDes] = [:]

        // Define userId as primary key with auto-increment
        let userIdColumn = LWDBColumnDes(autoincrement: true, notNull: true)
        userIdColumn.isPrimaryKey = true
        dict["userId"] = userIdColumn

        // Username must be unique
        let usernameColumn = LWDBColumnDes(autoincrement: false, unique: true, notNull: true)
        dict["username"] = usernameColumn

        return dict
    }
}
```

### 2. CRUD Operations

```swift
// Create
let user = User()
user.username = "john_doe"
user.email = "john@example.com"
user.save()

// Read
let users = User.findAll() as? [User] ?? []
let user = User.findByPK(1) as? User

// Update
user?.age = 26
user?.update()

// Delete
user?.deleteObject()
```

### 3. Query Builder (Fluent API)

```swift
let query: LWQueryBuilder<User> = User.query()
let results = query
    .where("age", ">", 18)
    .orderBy("age", ascending: false)
    .limit(10)
    .fetch()
```

### 4. SwiftUI Integration

```swift
@available(iOS 13.0, *)
class ObservableUser: ObservableLWDBModel {
    @objc dynamic var userId: Int = 0
    @objc dynamic var username: String = ""
}

struct UserDetailView: View {
    @ObservedObject var user: ObservableUser

    var body: some View {
        Form {
            TextField("Username", text: $user.username)
            Button("Save") {
                user.saveOrUpdate()
            }
        }
    }
}
```

### 5. Async/Await Support

```swift
@available(iOS 13.0, *)
func saveUserAsync() async {
    let user = User()
    user.username = "async_user"
    let success = await user.saveAsync()
}
```

### 6. Batch Operations with Transactions

```swift
var users: [User] = []
for i in 1...100 {
    let user = User()
    user.username = "user\\(i)"
    users.append(user)
}

// All saves happen in a transaction
if User.save(objects: users) {
    print("All users saved")
}
```

## API Comparison: Objective-C vs Swift

### Model Definition

**Objective-C:**
```objc
@interface User : LWDBModel
@property (nonatomic, assign) int userId;
@property (nonatomic, copy) NSString *username;
@end

@implementation User
+ (NSDictionary *)describeColumnDict {
    LWDBColumnDes *userIdColumn = [[LWDBColumnDes alloc] initWithAuto:YES isNotNull:YES check:nil defaultVa:nil];
    userIdColumn.primaryKey = YES;
    return @{@"userId": userIdColumn};
}
@end
```

**Swift:**
```swift
class User: LWDBModel {
    @objc var userId: Int = 0
    @objc var username: String = ""

    override class func describeColumnDict() -> [String: LWDBColumnDes] {
        var dict: [String: LWDBColumnDes] = [:]
        let userIdColumn = LWDBColumnDes(autoincrement: true, notNull: true)
        userIdColumn.isPrimaryKey = true
        dict["userId"] = userIdColumn
        return dict
    }
}
```

### CRUD Operations

**Objective-C:**
```objc
// Save
User *user = [[User alloc] init];
user.username = @"john";
[user save];

// Find
NSArray *users = [User findAll];
User *user = [User findByPK:@1];
```

**Swift:**
```swift
// Save
let user = User()
user.username = "john"
user.save()

// Find
let users = User.findAll() as? [User] ?? []
let user = User.findByPK(1) as? User
```

## Advanced Features

### 1. Custom Column Names

```swift
override class func describeColumnDict() -> [String: LWDBColumnDes] {
    var dict: [String: LWDBColumnDes] = [:]
    let nameColumn = LWDBColumnDes()
    nameColumn.columnName = "prod_name"  // DB column name differs from property
    dict["productName"] = nameColumn
    return dict
}
```

### 2. Excluding Properties from Database

```swift
override class func describeColumnDict() -> [String: LWDBColumnDes] {
    var dict: [String: LWDBColumnDes] = [:]
    let cacheColumn = LWDBColumnDes()
    cacheColumn.isUseless = true  // Won't create DB column
    dict["cachedData"] = cacheColumn
    return dict
}
```

### 3. Complex Queries

```swift
// Using criteria string
let users = User.find(byCriteria: "WHERE age > 18 AND status = 'active'") as? [User]

// Using query builder
let users: [User] = User.query()
    .where("age", ">", 18)
    .and("status", "=", "active")
    .fetch()
```

### 4. Database Configuration

```swift
let config = LWDatabaseConfig(
    directoryName: "MyApp",
    enableLogging: true
)
LWDatabaseManager.shared.configure(with: config)
```

## SQLite Type Mapping

| Swift Type | SQLite Type |
|-----------|-------------|
| String | TEXT |
| Int, Int32, Int64, Bool | INTEGER |
| Float, Double | REAL |
| Data | BLOB |

## Column Constraints

- **Primary Key**: `isPrimaryKey = true`
- **Auto Increment**: `isAutoincrement = true`
- **Unique**: `isUnique = true`
- **Not Null**: `isNotNull = true`
- **Default Value**: `defaultValue = "value"`
- **Foreign Key**: `foreignKey = "REFERENCES table(column)"`
- **Check Constraint**: `check = "age > 0"`

## Thread Safety

All database operations use `FMDatabaseQueue` for thread-safe access. You can safely perform database operations from any thread.

## Encryption

The database is encrypted using SQLCipher. The default encryption key is `"luowei.wodedata.com"`.

To customize the encryption key, override `LWSQLCipherDBTool.secretKey`:

```swift
extension LWSQLCipherDBTool {
    override open class var secretKey: String {
        return "your-custom-encryption-key"
    }
}
```

## Requirements

- iOS 8.0+ (iOS 13.0+ for SwiftUI and async/await features)
- Swift 5.0+
- FMDB
- SQLCipher

## Dependencies

This library depends on:
- **FMDB**: Objective-C wrapper for SQLite
- **SQLCipher**: SQLite extension for database encryption

## Migration from Objective-C

The Swift version maintains API compatibility with the Objective-C version. Key differences:

1. **Type Safety**: Swift provides better type safety with generics
2. **Optional Handling**: Swift uses optionals instead of nil checks
3. **Value Types**: Swift uses structs and enums where appropriate
4. **Modern Patterns**: Added SwiftUI, Combine, and async/await support
5. **Fluent API**: New query builder for more readable code

## Best Practices

1. **Always use @objc** for properties that need to be persisted
2. **Initialize properties** with default values
3. **Override describeColumnDict()** to define table schema
4. **Use transactions** for batch operations
5. **Use query builder** for complex queries
6. **Use Observable models** for SwiftUI integration

## Performance Tips

1. Use batch operations (`save(objects:)`) for multiple records
2. Use criteria-based queries instead of fetching all records
3. Create indexes on frequently queried columns
4. Use `limit` and `offset` for pagination
5. Close database connections when not needed

## License

MIT License - Same as the original Objective-C version

## Author

Swift version created based on the original Objective-C implementation by luowei
Copyright © 2017 luowei. All rights reserved.
