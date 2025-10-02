# LWSQLCipherDB

[![CI Status](https://img.shields.io/travis/luowei/LWSQLCipherDB.svg?style=flat)](https://travis-ci.org/luowei/LWSQLCipherDB)
[![Version](https://img.shields.io/cocoapods/v/LWSQLCipherDB.svg?style=flat)](https://cocoapods.org/pods/LWSQLCipherDB)
[![License](https://img.shields.io/cocoapods/l/LWSQLCipherDB.svg?style=flat)](https://cocoapods.org/pods/LWSQLCipherDB)
[![Platform](https://img.shields.io/cocoapods/p/LWSQLCipherDB.svg?style=flat)](https://cocoapods.org/pods/LWSQLCipherDB)

## 简介

LWSQLCipherDB 是一个基于 FMDB 和 SQLCipher 封装的 iOS 加密数据库组件。它提供了简洁的 ORM（对象关系映射）接口，让您可以轻松地进行加密数据库操作，同时支持多线程并发访问和事务处理。

### 主要特性

- **数据加密**: 基于 SQLCipher 的 AES-256 加密算法，保障数据安全
- **ORM 映射**: 自动将 Objective-C 对象映射为数据库表结构
- **线程安全**: 基于 FMDB 的队列机制，支持多线程并发操作
- **事务支持**: 批量操作自动使用事务，提升性能和数据一致性
- **灵活配置**: 支持主键、唯一约束、非空约束、默认值、外键等数据库特性
- **动态表结构**: 自动检测和更新表结构变化，无需手动迁移
- **条件查询**: 支持 SQL 条件查询和分页查询

## 系统要求

- iOS 8.0 或更高版本
- Objective-C

## 安装

### CocoaPods

LWSQLCipherDB 可通过 [CocoaPods](https://cocoapods.org) 安装。在您的 Podfile 中添加以下内容：

```ruby
pod 'LWSQLCipherDB'
```

然后执行：

```bash
pod install
```

## 核心类说明

### LWDBModel

所有数据模型的基类，提供完整的 CRUD（增删改查）操作接口。

### LWSQLCipherDBTool

数据库工具类，采用单例模式管理数据库连接。自动使用 SQLCipher 加密，默认密钥为 `luowei.wodedata.com`（建议在生产环境中修改）。

### LWDBColumnDes

数据库字段描述类，用于配置表字段的各种属性和约束。

### LWDBSQLState

SQL 条件语句构造器，用于构建 WHERE、AND、OR 等条件查询。

## 使用方法

### 1. 创建数据模型

创建一个继承自 `LWDBModel` 的类：

```objective-c
@interface User : LWDBModel

@property (nonatomic, copy) NSString *account;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *sex;
@property (nonatomic, assign) NSInteger age;
@property (nonatomic, copy) NSString *descn;
@property (nonatomic, assign) CGFloat height;
@property (nonatomic, copy) NSString *noField;  // 不需要存入数据库的字段

@end

@implementation User

// 必须重写此方法来配置字段属性
+ (NSDictionary *)describeColumnDict {
    // 配置主键
    LWDBColumnDes *account = [LWDBColumnDes new];
    account.primaryKey = YES;
    account.columnName = @"account_id";  // 设置数据库中的字段别名

    // 配置普通字段
    LWDBColumnDes *name = [[LWDBColumnDes alloc] initWithgeneralFieldWithAuto:NO
                                                                        unique:NO
                                                                     isNotNull:YES
                                                                         check:nil
                                                                     defaultVa:nil];

    // 配置不需要存入数据库的字段
    LWDBColumnDes *noField = [LWDBColumnDes new];
    noField.useless = YES;

    return @{@"account": account, @"name": name, @"noField": noField};
}

@end
```

### 2. 插入数据

#### 单条插入（多线程安全）

```objective-c
- (void)saveData {
    for (int i = 0; i < 5; i++) {
        User *user = [User new];
        user.account = [NSString stringWithFormat:@"%d", i];
        user.name = [NSString stringWithFormat:@"用户%d", i];
        user.sex = @"男";
        user.age = 20 + i;
        user.descn = @"这是用户描述";
        user.height = 175 + i;

        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [user save];  // 线程安全的插入操作
        });
    }
}
```

#### 批量插入（事务）

```objective-c
- (void)batchSaveData {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSMutableArray *array = [NSMutableArray array];
        for (int i = 0; i < 100; i++) {
            User *user = [[User alloc] init];
            user.name = [NSString stringWithFormat:@"批量用户%d", i];
            user.age = 10 + i;
            user.sex = @"女";
            user.account = [NSString stringWithFormat:@"%d", i];
            [array addObject:user];
        }
        // 使用事务批量插入，性能更优
        [User saveObjects:array];
    });
}
```

### 3. 更新数据

#### 单条更新

```objective-c
- (void)updateData {
    User *user = [User new];
    user.account = @"001";
    user.name = @"更新后的用户名";
    user.sex = @"男";
    user.descn = @"更新的描述信息";
    user.height = 185;

    // saveOrUpdate 会根据主键判断是插入还是更新
    [user saveOrUpdate];
}
```

#### 批量更新（事务）

```objective-c
- (void)batchUpdateData {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSMutableArray *array = [NSMutableArray array];
        for (int i = 0; i < 100; i++) {
            User *user = [[User alloc] init];
            user.account = [NSString stringWithFormat:@"%d", i];
            user.name = [NSString stringWithFormat:@"更新用户%d", i];
            user.age = 10 + i;
            user.sex = @"女";
            user.descn = @"事务更新";
            [array addObject:user];
        }
        [User saveOrUpdateObjects:array];
    });
}
```

#### 根据特定列更新

```objective-c
- (void)updateByColumn {
    User *user = [User new];
    user.name = @"张三";
    user.age = 25;
    // 根据 name 字段判断是否存在记录，存在则更新，不存在则插入
    [user saveOrUpdateByColumnName:@"name" AndColumnValue:@"张三"];
}
```

### 4. 删除数据

#### 单条删除

```objective-c
- (void)deleteData {
    User *user = [User new];
    user.account = @"001";
    [user deleteObject];
}
```

#### 批量删除（事务）

```objective-c
- (void)batchDeleteData {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSMutableArray *array = [NSMutableArray array];
        for (int i = 0; i < 100; i++) {
            User *user = [[User alloc] init];
            user.account = [NSString stringWithFormat:@"%d", i];
            [array addObject:user];
        }
        [User deleteObjects:array];
    });
}
```

#### 条件删除

```objective-c
- (void)deleteByCondition {
    // 使用 LWDBSQLState 构造条件
    LWDBSQLState *sql = [[LWDBSQLState alloc] object:[User class]
                                                 type:WHERE
                                                  key:@"age"
                                                  opt:@"<"
                                                value:@"20"];
    [User deleteObjectsWithFormat:[sql sqlOptionStr]];

    // 或者直接使用 SQL 条件字符串
    [User deleteObjectsByCriteria:@"WHERE age < 20"];
}
```

#### 清空表

```objective-c
- (void)clearAllData {
    [User clearTable];
}
```

### 5. 查询数据

#### 查询全部

```objective-c
- (void)queryAll {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSArray *users = [User findAll];
        for (User *user in users) {
            NSLog(@"用户信息：%@", user);
        }
    });
}
```

#### 根据主键查询

```objective-c
- (void)queryByPrimaryKey {
    User *user = [User findByPK:@"001"];
    NSLog(@"查询结果：%@", user);
}
```

#### 条件查询（单条）

```objective-c
- (void)queryFirstByCondition {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        LWDBSQLState *query = [[LWDBSQLState alloc] object:[User class]
                                                      type:WHERE
                                                       key:@"account"
                                                       opt:@"="
                                                     value:@"3"];
        User *user = [User findFirstByCriteria:[query sqlOptionStr]];
        NSLog(@"查询结果：%@", user);
    });
}
```

#### 条件查询（多条）

```objective-c
- (void)queryByCondition {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        // 使用 LWDBSQLState 构造条件
        LWDBSQLState *sql = [[LWDBSQLState alloc] object:[User class]
                                                    type:WHERE
                                                     key:@"age"
                                                     opt:@"<"
                                                   value:@"30"];
        NSArray *dataArray = [User findByCriteria:[sql sqlOptionStr]];

        for (User *user in dataArray) {
            NSLog(@"查询结果：%@", user);
        }
    });
}
```

#### 分页查询

```objective-c
- (void)queryWithPagination {
    static int rowid = 0;
    // 支持自定义 SQL 查询语句
    NSString *criteria = [NSString stringWithFormat:@"WHERE rowid > %d LIMIT 10", rowid];
    NSArray *array = [User findByCriteria:criteria];

    if (array.count > 0) {
        rowid += 10;  // 更新分页位置
        for (User *user in array) {
            NSLog(@"分页查询：%@", user);
        }
    }
}
```

#### 格式化查询

```objective-c
- (void)queryWithFormat {
    // 查询单条
    User *user = [User findFirstWithFormat:@"WHERE age = %d AND sex = '%@'", 25, @"男"];
    NSLog(@"查询结果：%@", user);

    // 查询多条
    NSArray *users = [User findWithFormat:@"WHERE age > %d ORDER BY age DESC", 20];
    for (User *user in users) {
        NSLog(@"查询结果：%@", user);
    }
}
```

### 6. 高级功能

#### 字段配置

```objective-c
@implementation Product

+ (NSDictionary *)describeColumnDict {
    // 配置自增主键
    LWDBColumnDes *productId = [[LWDBColumnDes alloc] initWithAuto:YES
                                                          isNotNull:YES
                                                              check:nil
                                                          defaultVa:nil];
    productId.primaryKey = YES;
    productId.columnName = @"product_id";

    // 配置唯一字段
    LWDBColumnDes *productCode = [[LWDBColumnDes alloc] initWithgeneralFieldWithAuto:NO
                                                                              unique:YES
                                                                           isNotNull:YES
                                                                               check:nil
                                                                           defaultVa:nil];

    // 配置带默认值的字段
    LWDBColumnDes *status = [[LWDBColumnDes alloc] initWithgeneralFieldWithAuto:NO
                                                                         unique:NO
                                                                      isNotNull:YES
                                                                          check:nil
                                                                      defaultVa:@"1"];

    // 配置带检查约束的字段
    LWDBColumnDes *price = [[LWDBColumnDes alloc] initWithgeneralFieldWithAuto:NO
                                                                        unique:NO
                                                                     isNotNull:YES
                                                                         check:@"price > 0"
                                                                     defaultVa:@"0"];

    return @{
        @"productId": productId,
        @"productCode": productCode,
        @"status": status,
        @"price": price
    };
}

@end
```

#### 切换数据库

```objective-c
- (void)switchDatabase {
    // 切换到指定目录下的数据库
    [[LWSQLCipherDBTool shareInstance] changeDBWithDirectoryName:@"UserData"];

    // 切换回默认数据库
    [[LWSQLCipherDBTool shareInstance] changeDBWithDirectoryName:nil];
}
```

#### 获取数据库路径

```objective-c
- (void)getDatabasePath {
    NSString *dbPath = [LWSQLCipherDBTool dbPath];
    NSLog(@"数据库路径：%@", dbPath);
}
```

#### 检查表是否存在

```objective-c
- (void)checkTableExists {
    BOOL exists = [User isExistInTable];
    if (exists) {
        NSLog(@"User 表已存在");
    } else {
        NSLog(@"User 表不存在");
    }
}
```

#### 手动创建表

```objective-c
- (void)createTable {
    BOOL success = [User createTable];
    if (success) {
        NSLog(@"表创建成功");
    } else {
        NSLog(@"表创建失败");
    }
}
```

#### 获取表的列信息

```objective-c
- (void)getTableColumns {
    NSArray *columns = [User getColumns];
    NSLog(@"User 表的列：%@", columns);
}
```

## 数据类型映射

LWSQLCipherDB 自动将 Objective-C 数据类型映射为 SQLite 数据类型：

| Objective-C 类型 | SQLite 类型 | 说明 |
|-----------------|------------|------|
| NSString, NSObject 及其他对象 | TEXT | 文本类型 |
| int, unsigned int, short, unsigned short, BOOL | INTEGER | 整数类型 |
| long, long long, unsigned long, unsigned long long | INTEGER | 长整数类型 |
| float, double | REAL | 浮点数类型 |

## 数据加密

LWSQLCipherDB 使用 SQLCipher 进行数据库加密，默认配置：

- **加密算法**: AES-256
- **默认密钥**: `luowei.wodedata.com`
- **加密模式**: SQLCIPHER_CRYPTO_CC（使用 iOS 系统的 CommonCrypto 框架）

### 修改加密密钥

建议在生产环境中修改默认密钥。在 `LWSQLCipherDBTool.m` 文件中修改：

```objective-c
@implementation FMDatabase (LWDBSwizzling)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [FMDatabase lwdb_swizzleMethod:@selector(secretKey) withMethod:@selector(mySecretKey)];
    });
}

- (NSString *)mySecretKey {
    return @"你的自定义密钥";  // 修改为您的密钥
}

@end
```

### 安全建议

1. **自定义密钥**: 不要使用默认密钥，应该生成一个强随机密钥
2. **密钥存储**: 密钥不应硬编码在代码中，建议使用 iOS Keychain 存储
3. **密钥管理**: 实现密钥的安全生成、存储和检索机制
4. **定期更新**: 根据安全策略定期更换加密密钥

## 线程安全

LWSQLCipherDB 基于 FMDB 的 `FMDatabaseQueue` 实现线程安全：

- 所有数据库操作都通过队列序列化执行
- 支持多线程同时调用，内部自动排队处理
- 批量操作使用事务保证数据一致性
- 无需手动管理数据库连接的打开和关闭

## 性能优化建议

1. **批量操作**: 使用 `saveObjects:`、`updateObjects:`、`deleteObjects:` 等批量方法，利用事务提升性能
2. **分页查询**: 对于大数据量查询，使用 `LIMIT` 和 `OFFSET` 进行分页
3. **索引优化**: 对经常查询的字段建立索引（需要手动执行 SQL）
4. **字段裁剪**: 使用 `useless` 属性排除不需要持久化的字段
5. **异步操作**: 将数据库操作放在子线程执行，避免阻塞主线程

## 注意事项

1. **主键必须**: 每个模型类必须配置至少一个主键字段
2. **重写方法**: 必须重写 `describeColumnDict` 方法来配置字段属性
3. **类型兼容**: 确保属性类型与数据库支持的类型兼容
4. **自动迁移**: 框架支持自动添加新字段，但不支持删除或修改现有字段
5. **密钥安全**: 务必在生产环境中修改默认加密密钥

## 常见问题

### Q: 如何修改已存在的表结构？

A: LWSQLCipherDB 支持自动添加新字段，但不支持删除字段。如需大幅修改表结构，建议：
- 创建新表
- 迁移数据
- 删除旧表
- 重命名新表

### Q: 如何实现数据库升级？

A: 框架会自动检测并添加新字段。对于复杂的升级需求，可以：
- 检查表结构
- 手动执行 SQL 进行数据迁移
- 使用 `changeDBWithDirectoryName:` 创建新数据库

### Q: 查询性能如何优化？

A: 建议：
- 使用分页查询避免一次加载过多数据
- 对常用查询字段建立索引
- 使用具体条件而不是 `findAll`
- 考虑使用缓存机制

### Q: 如何处理对象关系？

A: LWSQLCipherDB 是轻量级 ORM，不直接支持对象关系映射。建议：
- 使用外键字段存储关联对象的主键
- 手动实现关联查询逻辑
- 或考虑使用更完善的 ORM 框架

## 示例项目

要运行示例项目，请执行以下步骤：

1. 克隆仓库
2. 进入 Example 目录
3. 执行 `pod install`
4. 打开 `.xcworkspace` 文件
5. 运行项目

```bash
git clone https://github.com/luowei/LWSQLCipherDB.git
cd LWSQLCipherDB/Example
pod install
open LWSQLCipherDB.xcworkspace
```

## 依赖项

- [SQLCipher](https://www.zetetic.net/sqlcipher/): 提供 SQLite 数据库加密功能
- FMDB: SQLCipher 内部已包含 FMDB 的加密版本

## 作者

luowei - luowei@wodedata.com

## 许可证

LWSQLCipherDB 基于 MIT 许可证开源。详见 [LICENSE](LICENSE) 文件。

## 相关链接

- [GitHub 仓库](https://github.com/luowei/LWSQLCipherDB)
- [CocoaPods 主页](https://cocoapods.org/pods/LWSQLCipherDB)
- [SQLCipher 官方文档](https://www.zetetic.net/sqlcipher/documentation/)
- [FMDB GitHub](https://github.com/ccgus/fmdb)

## 更新日志

### 1.0.0
- 初始版本发布
- 支持基本的 CRUD 操作
- 集成 SQLCipher 加密
- 支持多线程安全操作
- 支持事务处理
- 支持动态表结构更新
