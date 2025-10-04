# LWSQLCipherDB

[![CI Status](https://img.shields.io/travis/luowei/LWSQLCipherDB.svg?style=flat)](https://travis-ci.org/luowei/LWSQLCipherDB)
[![Version](https://img.shields.io/cocoapods/v/LWSQLCipherDB.svg?style=flat)](https://cocoapods.org/pods/LWSQLCipherDB)
[![License](https://img.shields.io/cocoapods/l/LWSQLCipherDB.svg?style=flat)](https://cocoapods.org/pods/LWSQLCipherDB)
[![Platform](https://img.shields.io/cocoapods/p/LWSQLCipherDB.svg?style=flat)](https://cocoapods.org/pods/LWSQLCipherDB)

**Language:** [English](./README.md) | [中文版](./README_ZH.md)

---

## Table of Contents

- [Overview](#overview)
- [Key Features](#key-features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Core Concepts](#core-concepts)
- [API Reference](#api-reference)
- [CRUD Operations](#crud-operations-guide)
- [Advanced Features](#advanced-features)
- [Data Encryption](#data-encryption)
- [Thread Safety](#thread-safety)
- [Best Practices](#best-practices)
- [Performance Tips](#performance-tips)
- [Migration Guide](#migration-guide)
- [Troubleshooting](#troubleshooting)
- [Example Project](#example)
- [Contributing](#contributing)
- [License](#license)
- [Acknowledgments](#acknowledgments)

---

## Overview

LWSQLCipherDB is a powerful, lightweight, and thread-safe encrypted database wrapper for iOS based on FMDB and SQLCipher. It provides an ActiveRecord-style ORM interface that simplifies database operations with automatic encryption, making it easy to work with encrypted SQLite databases in iOS applications.

## Key Features

- **Encrypted Database**: Built on SQLCipher for automatic AES-256 encryption
- **Thread-Safe**: Built-in support for multi-threaded database operations using FMDatabaseQueue
- **ORM Pattern**: ActiveRecord-style interface for intuitive CRUD operations
- **Transaction Support**: Batch operations with automatic transaction management
- **Flexible Querying**: Support for complex SQL queries with builder pattern
- **Column Customization**: Fine-grained control over column attributes (primary keys, constraints, etc.)
- **Zero Configuration**: Automatic table creation and schema management

## Requirements

- iOS 8.0 or later
- Xcode 8.0 or later
- Objective-C

---

## Installation

LWSQLCipherDB is available through [CocoaPods](https://cocoapods.org). To install it, simply add the following line to your Podfile:

```ruby
pod 'LWSQLCipherDB'
```

For Swift version, use:

```ruby
pod 'LWSQLCipherDB_swift'
```

See [Swift Version Documentation](README_SWIFT_VERSION.md) for more details.

Then run:

```bash
pod install
```

## Quick Start

### 1. Create Your Model

Create a model class that inherits from `LWDBModel`:

```objective-c
#import "LWDBModel.h"

@interface User : LWDBModel
@property (nonatomic, copy) NSString *account;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *sex;
@property (nonatomic, assign) int age;
@property (nonatomic, assign) int height;
@property (nonatomic, copy) NSString *descn;
@end

@implementation User

// Configure column attributes
+ (NSDictionary *)describeColumnDict {
    // Set 'account' as primary key with custom column name
    LWDBColumnDes *account = [LWDBColumnDes new];
    account.primaryKey = YES;
    account.columnName = @"account_id";

    // Set 'name' as NOT NULL
    LWDBColumnDes *name = [[LWDBColumnDes alloc]
        initWithgeneralFieldWithAuto:NO
        unique:NO
        isNotNull:YES
        check:nil
        defaultVa:nil];

    return @{@"account": account, @"name": name};
}

@end
```

### 2. Perform CRUD Operations

```objective-c
// Create
User *user = [User new];
user.account = @"001";
user.name = @"John";
user.age = 25;
[user save];

// Read
User *foundUser = [User findByPK:@"001"];
NSArray *allUsers = [User findAll];

// Update
user.age = 26;
[user saveOrUpdate];

// Delete
[user deleteObject];
```

---

## Core Concepts

LWSQLCipherDB consists of four main components that work together to provide a complete encrypted database solution:

### LWDBModel

The base class for all data models. Provides complete CRUD (Create, Read, Update, Delete) operations with automatic table creation and schema management.

### LWSQLCipherDBTool

Singleton class that manages database connections and encryption. Handles database initialization, encryption key setup, and database switching.

### LWDBColumnDes

Column descriptor class for configuring individual column attributes including primary keys, constraints, default values, and data types.

### LWDBSQLState

SQL query builder for constructing WHERE clauses programmatically with support for complex conditions using AND/OR operators.

---

## Data Encryption

LWSQLCipherDB integrates SQLCipher for transparent database encryption, providing military-grade security for your data.

### Encryption Features

- **AES-256 Encryption**: All database files are automatically encrypted using SQLCipher
- **Transparent Operation**: Encryption/decryption happens automatically - no manual intervention needed
- **Zero Configuration**: Works out of the box with sensible defaults
- **SQLCipher Compatibility**: Uses industry-standard SQLCipher encryption
- **Minimal Performance Impact**: Optimized for mobile devices

### Default Configuration

- **Encryption Algorithm**: AES-256
- **Default Encryption Key**: `luowei.wodedata.com` (**must be changed in production**)
- **Crypto Provider**: SQLCIPHER_CRYPTO_CC (iOS CommonCrypto framework)

### Setting Custom Encryption Key

**Important**: Always change the default encryption key in production environments.

To set a custom encryption key, modify the `mySecretKey` method in your `FMDatabase` category:

```objective-c
@implementation FMDatabase (CustomKey)

- (NSString *)mySecretKey {
    return @"your-secure-production-key";
}

@end
```

### Security Best Practices

1. **Use Strong Keys**: Generate a strong, random encryption key (minimum 32 characters)
2. **Secure Key Storage**: Store encryption keys in iOS Keychain, never hardcode in source
3. **Key Management**: Implement secure key generation, storage, and retrieval mechanisms
4. **Regular Rotation**: Consider key rotation policies based on your security requirements
5. **Device-Specific Keys**: Consider generating unique keys per device for enhanced security

### Database Security Benefits

- **Data Protection**: All data is encrypted at rest
- **Secure Against Attacks**: Protection against unauthorized database access
- **Compliance**: Helps meet data protection and privacy regulations
- **Transparent to Application**: No changes needed in your data models

---

## API Reference

### LWDBModel - Base Model Class

All model classes should inherit from `LWDBModel`.

#### Properties

```objective-c
@property (nonatomic, assign) int pk;  // SQLite rowid
@property (retain, readonly, nonatomic) NSMutableArray *propertyNames;  // Property names
@property (retain, readonly, nonatomic) NSMutableArray *columeTypes;    // Column types
@property (retain, readonly, nonatomic) NSMutableArray *columeNames;    // Column names
```

#### Required Method

```objective-c
// Must be overridden in subclass to configure column attributes
+ (NSDictionary *)describeColumnDict;
```

#### Create Operations

```objective-c
// Save a single record
- (BOOL)save;

// Save multiple records in a transaction
+ (BOOL)saveObjects:(NSArray *)array;

// Save or update a single record
- (BOOL)saveOrUpdate;

// Save or update based on specific column
- (BOOL)saveOrUpdateByColumnName:(NSString *)columnName
                  AndColumnValue:(NSString *)columnValue;

// Save or update multiple records in a transaction
+ (BOOL)saveOrUpdateObjects:(NSArray *)array;
```

#### Read Operations

```objective-c
// Find all records
+ (NSArray *)findAll;

// Find by primary key
+ (instancetype)findByPK:(id)inPk;

// Find first record matching criteria
+ (instancetype)findFirstByCriteria:(NSString *)criteria;

// Find first record with format string
+ (instancetype)findFirstWithFormat:(NSString *)format, ...;

// Find all records matching criteria
+ (NSArray *)findByCriteria:(NSString *)criteria;

// Find all records with format string
+ (NSArray *)findWithFormat:(NSString *)format, ...;
```

#### Update Operations

```objective-c
// Update a single record
- (BOOL)update;

// Update multiple records in a transaction
+ (BOOL)updateObjects:(NSArray *)array;

// Save or update (see Create Operations)
- (BOOL)saveOrUpdate;
+ (BOOL)saveOrUpdateObjects:(NSArray *)array;
```

#### Delete Operations

```objective-c
// Delete a single record
- (BOOL)deleteObject;

// Delete multiple records in a transaction
+ (BOOL)deleteObjects:(NSArray *)array;

// Delete records matching criteria
+ (BOOL)deleteObjectsByCriteria:(NSString *)criteria;

// Delete records with format string
+ (BOOL)deleteObjectsWithFormat:(NSString *)format, ...;

// Clear entire table
+ (BOOL)clearTable;
```

#### Table Management

```objective-c
// Create table (called automatically on first use)
+ (BOOL)createTable;

// Check if table exists
+ (BOOL)isExistInTable;

// Get all columns in table
+ (NSArray *)getColumns;

// Get all properties
+ (NSDictionary *)getPropertys;
+ (NSDictionary *)getAllProperties;
```

### LWDBColumnDes - Column Configuration

Configure individual column attributes and constraints.

#### Properties

```objective-c
@property (nonatomic, copy) NSString *columnName;      // Custom column name
@property (nonatomic, copy) NSString *check;           // CHECK constraint
@property (nonatomic, copy) NSString *defaultValue;    // DEFAULT value
@property (nonatomic, copy) NSString *foreignKey;      // FOREIGN KEY
@property (nonatomic, assign) BOOL primaryKey;         // PRIMARY KEY
@property (nonatomic, assign) BOOL unique;             // UNIQUE constraint
@property (nonatomic, assign) BOOL notNull;            // NOT NULL constraint
@property (nonatomic, assign) BOOL autoincrement;      // AUTOINCREMENT
@property (nonatomic, assign) BOOL useless;            // Exclude from database
```

#### Initialization Methods

```objective-c
// Primary key field
- (instancetype)initWithAuto:(BOOL)isAutoincrement
                   isNotNull:(BOOL)notNull
                       check:(NSString *)check
                   defaultVa:(NSString *)defaultValue;

// General field
- (instancetype)initWithgeneralFieldWithAuto:(BOOL)isAutoincrement
                                      unique:(BOOL)isUnique
                                   isNotNull:(BOOL)notNull
                                       check:(NSString *)check
                                   defaultVa:(NSString *)defaultValue;

// Foreign key field
- (instancetype)initWithFKFiekdUnique:(BOOL)isUnique
                            isNotNull:(BOOL)notNull
                                check:(NSString *)check
                              default:(NSString *)defaultValue
                           foreignKey:(NSString *)foreignKey;
```

### LWDBSQLState - SQL Query Builder

Build SQL WHERE clauses programmatically.

#### Query Types

```objective-c
typedef NS_ENUM(NSInteger, QueryType) {
    WHERE = 0,  // WHERE clause
    AND,        // AND condition
    OR          // OR condition
};
```

#### Methods

```objective-c
// Build query condition
- (LWDBSQLState *)object:(Class)obj
                    type:(QueryType)type
                     key:(id)key
                     opt:(NSString *)opt
                   value:(id)value;

// Generate SQL string
- (NSString *)sqlOptionStr;
```

#### Usage Example

```objective-c
// Simple WHERE query
LWDBSQLState *query = [[LWDBSQLState alloc]
    object:[User class]
    type:WHERE
    key:@"age"
    opt:@">"
    value:@"18"];
NSArray *users = [User findByCriteria:[query sqlOptionStr]];

// Complex query with AND
LWDBSQLState *query1 = [[LWDBSQLState alloc]
    object:[User class]
    type:WHERE
    key:@"age"
    opt:@">="
    value:@"18"];

LWDBSQLState *query2 = [[LWDBSQLState alloc]
    object:[User class]
    type:AND
    key:@"sex"
    opt:@"="
    value:@"Male"];

NSString *sql = [[query1 sqlOptionStr] stringByAppendingString:[query2 sqlOptionStr]];
NSArray *users = [User findByCriteria:sql];
```

### LWSQLCipherDBTool - Database Management

Singleton class for managing database connections.

#### Methods

```objective-c
// Get shared instance
+ (instancetype)shareInstance;

// Get database path
+ (NSString *)dbPath;

// Switch to different database
- (BOOL)changeDBWithDirectoryName:(NSString *)directoryName;

// Access database queue
@property (nonatomic, retain, readonly) FMDatabaseQueue *dbQueue;
```

---

## CRUD Operations Guide

This section provides comprehensive examples for Create, Read, Update, and Delete operations.

### Create (Insert) Operations

#### Single Record Insert

```objective-c
User *user = [User new];
user.account = @"001";
user.name = @"Alice";
user.sex = @"Female";
user.age = 25;
[user save];
```

#### Batch Insert with Transaction

```objective-c
NSMutableArray *users = [NSMutableArray array];
for (int i = 0; i < 100; i++) {
    User *user = [[User alloc] init];
    user.account = [NSString stringWithFormat:@"%d", i];
    user.name = [NSString stringWithFormat:@"User%d", i];
    user.age = 20 + i;
    [users addObject:user];
}
[User saveObjects:users];  // All saved in one transaction
```

#### Multi-threaded Insert

```objective-c
for (int i = 0; i < 5; i++) {
    User *user = [User new];
    user.account = [NSString stringWithFormat:@"%d", i];
    user.name = [NSString stringWithFormat:@"User%d", i];

    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [user save];  // Thread-safe
    });
}
```

### Read (Query) Operations

#### Query All Records

```objective-c
NSArray *allUsers = [User findAll];
for (User *user in allUsers) {
    NSLog(@"User: %@, Age: %d", user.name, user.age);
}
```

#### Query by Primary Key

```objective-c
User *user = [User findByPK:@"001"];
```

#### Conditional Query

```objective-c
// Using LWDBSQLState
LWDBSQLState *query = [[LWDBSQLState alloc]
    object:[User class]
    type:WHERE
    key:@"age"
    opt:@">"
    value:@"25"];
NSArray *users = [User findByCriteria:[query sqlOptionStr]];

// Using format string
NSArray *users = [User findWithFormat:@"WHERE age > %d", 25];
```

#### Query First Record

```objective-c
LWDBSQLState *query = [[LWDBSQLState alloc]
    object:[User class]
    type:WHERE
    key:@"account"
    opt:@"="
    value:@"001"];
User *user = [User findFirstByCriteria:[query sqlOptionStr]];
```

#### Pagination Query

```objective-c
// Page 1: First 10 records
NSArray *page1 = [User findByCriteria:@"LIMIT 10 OFFSET 0"];

// Page 2: Next 10 records
NSArray *page2 = [User findByCriteria:@"LIMIT 10 OFFSET 10"];

// Using rowid for pagination
static int lastRowId = 0;
NSArray *nextPage = [User findByCriteria:
    [NSString stringWithFormat:@"WHERE rowid > %d LIMIT 10", lastRowId]];
```

#### Advanced Queries

```objective-c
// ORDER BY
NSArray *users = [User findByCriteria:@"ORDER BY age DESC"];

// Complex conditions
NSArray *users = [User findByCriteria:
    @"WHERE age BETWEEN 20 AND 30 AND sex = 'Male' ORDER BY age"];

// LIKE query
NSArray *users = [User findByCriteria:@"WHERE name LIKE '%John%'"];
```

### Update Operations

#### Single Record Update

```objective-c
User *user = [User findByPK:@"001"];
user.age = 30;
user.name = @"Updated Name";
[user update];
```

#### Save or Update

```objective-c
// If record exists (by primary key), update; otherwise insert
User *user = [User new];
user.account = @"001";  // Primary key
user.name = @"New or Updated";
user.age = 28;
[user saveOrUpdate];
```

#### Batch Update with Transaction

```objective-c
NSMutableArray *users = [NSMutableArray array];
for (int i = 0; i < 100; i++) {
    User *user = [[User alloc] init];
    user.account = [NSString stringWithFormat:@"%d", i];
    user.age = 30 + i;
    [users addObject:user];
}
[User saveOrUpdateObjects:users];  // All updated in one transaction
```

#### Multi-threaded Update

```objective-c
for (int i = 0; i < 5; i++) {
    User *user = [User new];
    user.account = [NSString stringWithFormat:@"%d", i];
    user.name = @"Updated";

    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [user saveOrUpdate];  // Thread-safe
    });
}
```

### Delete Operations

#### Single Record Delete

```objective-c
User *user = [User findByPK:@"001"];
[user deleteObject];
```

#### Conditional Delete

```objective-c
// Using LWDBSQLState
LWDBSQLState *sql = [[LWDBSQLState alloc]
    object:[User class]
    type:WHERE
    key:@"age"
    opt:@"<"
    value:@"18"];
[User deleteObjectsByCriteria:[sql sqlOptionStr]];

// Using format string
[User deleteObjectsWithFormat:@"WHERE age < %d", 18];
```

#### Batch Delete with Transaction

```objective-c
NSMutableArray *users = [NSMutableArray array];
for (int i = 0; i < 10; i++) {
    User *user = [[User alloc] init];
    user.account = [NSString stringWithFormat:@"%d", i];
    [users addObject:user];
}
[User deleteObjects:users];  // All deleted in one transaction
```

#### Clear Table

```objective-c
// Delete all records from table
[User clearTable];
```

#### Multi-threaded Delete

```objective-c
for (int i = 0; i < 5; i++) {
    User *user = [User new];
    user.account = [NSString stringWithFormat:@"%d", i];

    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [user deleteObject];  // Thread-safe
    });
}
```

---

## Thread Safety

LWSQLCipherDB provides comprehensive thread safety through FMDB's `FMDatabaseQueue` mechanism, allowing safe concurrent access from multiple threads.

### How It Works

- **Automatic Serialization**: All database operations are automatically serialized through a queue
- **No Manual Locking**: No need to manage locks, semaphores, or synchronization
- **Multi-thread Support**: Safe to call database methods from any thread simultaneously
- **Transaction Safety**: Batch operations are wrapped in transactions automatically

### Thread-Safe Operations

All database operations are inherently thread-safe:

```objective-c
// Safe to call from multiple threads simultaneously
dispatch_async(dispatch_get_global_queue(0, 0), ^{
    User *user1 = [User new];
    user1.account = @"001";
    [user1 save];
});

dispatch_async(dispatch_get_global_queue(0, 0), ^{
    User *user2 = [User new];
    user2.account = @"002";
    [user2 save];
});

dispatch_async(dispatch_get_global_queue(0, 0), ^{
    NSArray *users = [User findAll];
});
```

### Benefits

- **Simplified Code**: No need to manage database connections or threading
- **Deadlock Prevention**: Queue-based architecture prevents deadlocks
- **Consistent State**: Transactions ensure data consistency across operations
- **Performance**: Efficient queue management minimizes overhead

---

## Advanced Features

### Custom Column Configuration

```objective-c
+ (NSDictionary *)describeColumnDict {
    // Primary key with auto-increment
    LWDBColumnDes *userId = [[LWDBColumnDes alloc]
        initWithAuto:YES
        isNotNull:YES
        check:nil
        defaultVa:nil];
    userId.primaryKey = YES;

    // Unique field
    LWDBColumnDes *email = [LWDBColumnDes new];
    email.unique = YES;
    email.notNull = YES;

    // Field with default value
    LWDBColumnDes *status = [LWDBColumnDes new];
    status.defaultValue = @"'active'";

    // Field with CHECK constraint
    LWDBColumnDes *age = [LWDBColumnDes new];
    age.check = @"age >= 0 AND age <= 150";

    // Custom column name
    LWDBColumnDes *userName = [LWDBColumnDes new];
    userName.columnName = @"user_name";

    // Exclude property from database
    LWDBColumnDes *tempData = [LWDBColumnDes new];
    tempData.useless = YES;

    return @{
        @"userId": userId,
        @"email": email,
        @"status": status,
        @"age": age,
        @"userName": userName,
        @"tempData": tempData
    };
}
```

### Multiple Database Support

```objective-c
// Switch to different database
[[LWSQLCipherDBTool shareInstance] changeDBWithDirectoryName:@"UserDB"];

// Switch to another database
[[LWSQLCipherDBTool shareInstance] changeDBWithDirectoryName:@"CacheDB"];
```

### Transaction Management

Batch operations automatically use transactions for better performance and data consistency:

```objective-c
// All these operations are automatically wrapped in transactions
[User saveObjects:arrayOfUsers];        // Single transaction for all saves
[User updateObjects:arrayOfUsers];      // Single transaction for all updates
[User deleteObjects:arrayOfUsers];      // Single transaction for all deletes
[User saveOrUpdateObjects:arrayOfUsers]; // Single transaction for all operations
```

**Benefits of Transaction-based Batch Operations:**
- **Atomicity**: All operations succeed or fail together
- **Performance**: Up to 100x faster than individual operations
- **Data Consistency**: Ensures database remains in valid state
- **Automatic Rollback**: Failed operations don't leave partial changes

---

## Data Types

LWSQLCipherDB automatically maps Objective-C types to SQLite types:

| Objective-C Type | SQLite Type | Description |
|-----------------|-------------|-------------|
| `NSString`      | TEXT        | Text strings |
| `int`, `NSInteger` | INTEGER  | Integer numbers |
| `short`, `unsigned int` | INTEGER | Integer variants |
| `long`, `long long` | INTEGER | Long integers |
| `float`, `double` | REAL      | Floating-point numbers |
| `CGFloat`       | REAL        | Core Graphics float |
| `BOOL`          | INTEGER     | Boolean (0 or 1) |
| `NSData`        | BLOB        | Binary data |
| `nil`           | NULL        | Null values |

### Type Constants

```objective-c
#define SQLTEXT     @"TEXT"
#define SQLINTEGER  @"INTEGER"
#define SQLREAL     @"REAL"
#define SQLBLOB     @"BLOB"
#define SQLNULL     @"NULL"
```

---

## Best Practices

### 1. Always Define Primary Keys

Every model should have at least one primary key for efficient lookups and updates:

```objective-c
+ (NSDictionary *)describeColumnDict {
    LWDBColumnDes *userId = [LWDBColumnDes new];
    userId.primaryKey = YES;
    return @{@"userId": userId};
}
```

### 2. Use Batch Operations for Multiple Records

Always prefer batch operations over loops for better performance:

```objective-c
// Good - Single transaction
[User saveObjects:largeArray];

// Bad - Multiple individual transactions
for (User *user in largeArray) {
    [user save];  // Each save is a separate transaction
}
```

### 3. Change Default Encryption Key

Never use the default encryption key in production:

```objective-c
// Override in your FMDatabase category
- (NSString *)mySecretKey {
    return @"your-secure-production-key";
}
```

### 4. Perform Heavy Operations on Background Threads

Keep the main thread responsive by performing database operations asynchronously:

```objective-c
dispatch_async(dispatch_get_global_queue(0, 0), ^{
    // Perform large database operation
    NSArray *results = [User findAll];

    dispatch_async(dispatch_get_main_queue(), ^{
        // Update UI with results
    });
});
```

### 5. Implement Proper Error Handling

Always check return values for database operations:

```objective-c
BOOL success = [user save];
if (!success) {
    NSLog(@"Failed to save user: %@", user);
    // Handle error appropriately
}
```

### 6. Use Query Conditions to Limit Results

Avoid loading unnecessary data:

```objective-c
// Good - Load only what you need
NSArray *activeUsers = [User findByCriteria:@"WHERE status = 'active' LIMIT 100"];

// Bad - Load everything
NSArray *allUsers = [User findAll];
```

### 7. Exclude Transient Properties

Mark properties that shouldn't be persisted with `useless`:

```objective-c
+ (NSDictionary *)describeColumnDict {
    LWDBColumnDes *tempData = [LWDBColumnDes new];
    tempData.useless = YES;  // Won't be saved to database
    return @{@"tempData": tempData};
}
```

---

## Performance Tips

### 1. Use Batch Operations

Batch operations are significantly faster due to transaction overhead reduction:

```objective-c
// Up to 100x faster for large datasets
[User saveObjects:thousandsOfUsers];
```

### 2. Implement Pagination

For large result sets, use pagination to reduce memory usage:

```objective-c
int pageSize = 50;
int offset = 0;
NSArray *page = [User findByCriteria:
    [NSString stringWithFormat:@"LIMIT %d OFFSET %d", pageSize, offset]];
```

### 3. Add Indexes for Frequently Queried Columns

While not directly supported by the API, you can execute custom SQL to add indexes:

```objective-c
// Execute through FMDatabaseQueue for frequently queried columns
```

### 4. Reuse Query Strings

Cache frequently used query strings to avoid recreation:

```objective-c
static NSString *activeUsersQuery = @"WHERE status = 'active'";
NSArray *users = [User findByCriteria:activeUsersQuery];
```

### 5. Profile Your Queries

Monitor query performance and optimize slow queries:

```objective-c
NSDate *start = [NSDate date];
NSArray *results = [User findByCriteria:complexQuery];
NSTimeInterval duration = [[NSDate date] timeIntervalSinceDate:start];
NSLog(@"Query took: %.3f seconds", duration);
```

---

## Migration Guide

### Adding New Columns

LWSQLCipherDB automatically detects and adds new columns:

```objective-c
// 1. Add new property to your model
@property (nonatomic, copy) NSString *email;

// 2. Update describeColumnDict
+ (NSDictionary *)describeColumnDict {
    LWDBColumnDes *email = [LWDBColumnDes new];
    email.notNull = NO;  // Make nullable for existing rows
    return @{@"email": email};
}

// 3. The column will be added automatically on next operation
```

### Modifying Existing Columns

SQLite has limited ALTER TABLE support. For complex changes:

```objective-c
// 1. Create new table with desired schema
// 2. Copy data from old table
// 3. Drop old table
// 4. Rename new table

// This requires manual SQL execution through FMDatabaseQueue
```

### Data Migration Between Versions

Handle schema migrations at app startup:

```objective-c
- (void)migrateDatabase {
    NSString *currentVersion = @"1.0";
    NSString *lastVersion = [[NSUserDefaults standardUserDefaults]
                             stringForKey:@"DatabaseVersion"];

    if (![currentVersion isEqualToString:lastVersion]) {
        // Perform migration
        [self performMigrationFromVersion:lastVersion to:currentVersion];

        // Update version
        [[NSUserDefaults standardUserDefaults]
         setObject:currentVersion forKey:@"DatabaseVersion"];
    }
}
```

---

## Troubleshooting

### Database is Locked

**Issue**: Error messages about locked database.

**Solution**: The library automatically handles this through `FMDatabaseQueue`. If you see this error, ensure you're using the provided methods and not accessing the database directly.

### Data Not Persisting

**Possible Causes:**

1. Model doesn't inherit from `LWDBModel`:
```objective-c
@interface User : LWDBModel  // Must inherit from LWDBModel
```

2. Missing or incorrect `describeColumnDict`:
```objective-c
+ (NSDictionary *)describeColumnDict {
    return @{};  // At minimum, return empty dictionary
}
```

3. No primary key defined:
```objective-c
// Always define at least one primary key
LWDBColumnDes *userId = [LWDBColumnDes new];
userId.primaryKey = YES;
```

### Cannot Read Encrypted Database

**Issue**: Database appears corrupted or unreadable.

**Solution**: Ensure the encryption key is consistent across app launches. The key must be exactly the same every time.

```objective-c
// Key must remain constant
- (NSString *)mySecretKey {
    return @"exact-same-key-every-time";
}
```

### Query Returns Unexpected Results

**Debugging Steps:**

1. Verify your query syntax:
```objective-c
NSString *query = @"WHERE age > 25 AND status = 'active'";
NSLog(@"Query: %@", query);
NSArray *results = [User findByCriteria:query];
```

2. Check column names match property names (or custom column names)

3. Verify data types are compatible

### Performance Issues

**If operations are slow:**

1. Use batch operations instead of loops
2. Implement pagination for large result sets
3. Move operations to background threads
4. Consider adding indexes (manual SQL)
5. Profile queries to identify bottlenecks

---

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

```Objective-C
@implementation LWViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

//Insert 5 items with multiple threads
- (IBAction)saveData1:(id)sender {
    for (int i = 0; i < 5; i++) {
        User *user = [User new];
        user.account = [NSString stringWithFormat:@"%d",i];
        user.name = [NSString stringWithFormat:@"帅哥%d",i];
        user.sex = @"男";
        user.age = i;
        user.descn = @"I'm Jack";
        user.height = 175+i;

        dispatch_async(dispatch_get_global_queue(0,0), ^{
            [user save];
        });

    }
}
//Create a queue to insert 5 items
- (IBAction)saveData2:(id)sender {
    dispatch_queue_t q1 = dispatch_queue_create("queue1", NULL);
    dispatch_async(q1, ^{
        for (int i = 5; i < 10; ++i) {
            User *user = [[User alloc] init];
            user.account = [NSString stringWithFormat:@"%d",i];
            user.name = @"欧巴";
            user.sex = @"女Or男";
            user.age = i+5;
            [user save];
        }
    });
}
//100 transactions were inserted
- (IBAction)saveData3:(id)sender {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSMutableArray *array = [NSMutableArray array];
        for (int i = 0; i < 100; i++) {
            User *user = [[User alloc] init];
            user.name = [NSString stringWithFormat:@"呵呵%d",i];
            user.age = 10+i;
            user.sex = @"女";
            user.account = [NSString stringWithFormat:@"%d",i];
            [array addObject:user];
        }
        [User saveObjects:array];
    });
}

//Conditions to delete
- (IBAction)delete:(id)sender {
    LWDBSQLState *sql = [[LWDBSQLState alloc] object:[User class] type:WHERE key:@"age" opt:@"=" value:@"4"];

    [User deleteObjectsWithFormat:[sql sqlOptionStr]];

}

//Multiple child thread deletion
- (IBAction)delete1:(id)sender {
    for (int i = 0; i < 5; i++) {
        User *user = [User new];
        user.account = [NSString stringWithFormat:@"%d",i];
        user.name = [NSString stringWithFormat:@"帅哥%d",i];
        user.sex = @"男";
        user.descn = @"I'm Jack";
        user.height = 185;
        dispatch_async(dispatch_get_global_queue(0,0), ^{
            [user deleteObject];
        });

    }
}
//Transaction to delete
- (IBAction)detete2:(id)sender {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSMutableArray *array = [NSMutableArray array];
        for (int i = 0; i < 100; i++) {
            User *user = [[User alloc] init];
            user.name = [NSString stringWithFormat:@"呵呵%d",i];
            user.age = 10+i;
            user.sex = @"女";
            [array addObject:user];
        }
        [User deleteObjects:array];
    });
}


//Multiple child thread updates
- (IBAction)update1:(id)sender {
    for (int i = 0; i < 5; i++) {
        User *user = [User new];
        user.account = [NSString stringWithFormat:@"%d",i];
        user.name = [NSString stringWithFormat:@"帅哥%d",i];
        user.sex = @"男";
        user.descn = @"我是更新的数据:我是帅哥我自豪";
        user.height = 185;
        dispatch_async(dispatch_get_global_queue(0,0), ^{
            [user saveOrUpdate];
        });
    }


}
//Update transaction
- (IBAction)update2:(id)sender {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSMutableArray *array = [NSMutableArray array];
        for (int i = 0; i < 100; i++) {
            User *user = [[User alloc] init];
            user.name = [NSString stringWithFormat:@"呵呵%d",i];
            user.age = 10+i;
            user.sex = @"女";
            user.descn = @"我是事务更新-呵呵";
            [array addObject:user];
        }
        [User saveOrUpdateObjects:array];
    });
}
//Look up a piece of data
- (IBAction)query1:(id)sender {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        LWDBSQLState *query = [[LWDBSQLState alloc] object:[User class] type:WHERE key:@"account" opt:@"=" value:@"3"];

        User *users = [User findFirstByCriteria:[query sqlOptionStr]];
        NSLog(@"第一条:%@",users);
    });
}
//condition query
- (IBAction)query2:(id)sender {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        LWDBSQLState *sql = [[LWDBSQLState alloc] object:[User class] type:WHERE key:@"age" opt:@"<" value:@"4"];

        NSArray *dataArray = [User findByCriteria:[sql sqlOptionStr]];

        for (User *user in dataArray) {
            NSLog(@"条件查询%@",user);
        }

    });
}
//Query all
- (IBAction)query3:(id)sender {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        for (User *user in [User findAll]) {
            NSLog(@"全部%@",user);
        }

    });
}
//Paging query
- (IBAction)query4:(id)sender {
    static int rowid = 0;
    //支持自定义查询语句  sql查询过多  具体请查看sql写法
    //LKDBSQLState只支持一般常用sql语句
    NSArray *array = [User findByCriteria:[NSString stringWithFormat:@" WHERE rowid > %d limit 10",rowid]];

    for (User *user in array) {
        NSLog(@"分页查询%@",user);
    }
}

//Query symbol list
- (IBAction)querySymbolList:(id)sender {
    
}

@end



@implementation User

//must overwirte this method
+ (NSDictionary *)describeColumnDict{
    LWDBColumnDes *account = [LWDBColumnDes new];
    account.primaryKey = YES;
    account.columnName = @"account_id";

    LWDBColumnDes *name = [[LWDBColumnDes alloc] initWithgeneralFieldWithAuto:NO unique:NO isNotNull:YES check:nil defaultVa:nil];

    LWDBColumnDes *noField = [LWDBColumnDes new];
    noField.useless = YES;

    return @{@"account":account,@"name":name,@"noField":noField};
}
@end

```

---

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### How to Contribute

1. **Fork the repository**
2. **Create your feature branch**
   ```bash
   git checkout -b feature/amazing-feature
   ```
3. **Commit your changes**
   ```bash
   git commit -m 'Add some amazing feature'
   ```
4. **Push to the branch**
   ```bash
   git push origin feature/amazing-feature
   ```
5. **Open a Pull Request**

### Guidelines

- Follow the existing code style
- Add tests for new features
- Update documentation as needed
- Ensure all tests pass before submitting

---

## Author

**luowei**

- Email: luowei@wodedata.com
- Website: [http://wodedata.com](http://wodedata.com)
- GitHub: [@luowei](https://github.com/luowei)

---

## License

LWSQLCipherDB is available under the MIT License. See the [LICENSE](LICENSE) file for more information.

### MIT License

```
Copyright (c) 2025 luowei

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## Acknowledgments

LWSQLCipherDB builds upon excellent open-source projects:

- **[FMDB](https://github.com/ccgus/fmdb)** - A Cocoa/Objective-C wrapper around SQLite by [Gus Mueller](https://github.com/ccgus)
- **[SQLCipher](https://www.zetetic.net/sqlcipher/)** - SQLCipher is an open source extension to SQLite that provides transparent 256-bit AES encryption by [Zetetic LLC](https://www.zetetic.net)

### Related Resources

- [FMDB Documentation](https://github.com/ccgus/fmdb)
- [SQLCipher Official Site](https://www.zetetic.net/sqlcipher/)
- [SQLCipher GitHub Repository](https://github.com/sqlcipher/sqlcipher)
- [SQLite Documentation](https://www.sqlite.org/docs.html)
- [CocoaPods](https://cocoapods.org/pods/LWSQLCipherDB)

---

## Support

If you encounter any issues or have questions:

1. Check the [Troubleshooting](#troubleshooting) section
2. Search [existing issues](https://github.com/luowei/LWSQLCipherDB/issues)
3. Create a [new issue](https://github.com/luowei/LWSQLCipherDB/issues/new) if needed

---

<div align="center">

**LWSQLCipherDB** - Secure, Simple, Swift Database Operations

Made with care by [luowei](http://wodedata.com)

[⬆ Back to Top](#lwsqlcipherdb)

</div>
