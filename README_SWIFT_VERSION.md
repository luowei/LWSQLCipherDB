# LWSQLCipherDB Swift版本使用说明

## 概述

LWSQLCipherDB提供了Swift版本的实现，专门为使用Swift开发的项目优化，提供更现代化的加密SQLite数据库操作功能。

## 安装

### CocoaPods

在你的`Podfile`中添加：

```ruby
pod 'LWSQLCipherDB_swift'
```

然后运行：

```bash
pod install
```

## 要求

- iOS 13.0+
- Swift 5.0+
- Xcode 12.0+

## Swift版本包含的功能

Swift版本包含以下组件：

- `LWDBColumnDes.swift` - 数据库列描述
- `LWDBSQLState.swift` - SQL状态管理
- `LWSQLCipherDBTool.swift` - 数据库工具类
- `LWDBModel.swift` - 数据库模型基类
- `LWSQLCipherDB.swift` - 主数据库类
- `ExampleUsage.swift` - 使用示例

## 使用示例

### 基础用法

```swift
import LWSQLCipherDB_swift

// 定义数据模型
class User: LWDBModel {
    var id: Int = 0
    var name: String = ""
    var age: Int = 0
    var email: String = ""
}

// 创建加密数据库
let dbPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! + "/user.db"
let password = "mySecretPassword"
let db = LWSQLCipherDB(path: dbPath, password: password)

// 创建表
db.createTable(User.self)

// 插入数据
let user = User()
user.name = "张三"
user.age = 25
user.email = "zhangsan@example.com"
db.insert(user)

// 查询数据
let users = db.query(User.self, where: "age > ?", params: [20])
for user in users {
    print("姓名: \(user.name), 年龄: \(user.age)")
}

// 更新数据
user.age = 26
db.update(user, where: "name = ?", params: ["张三"])

// 删除数据
db.delete(User.self, where: "age < ?", params: [18])
```

### 高级用法

```swift
// 事务操作
db.transaction { database in
    let user1 = User()
    user1.name = "李四"
    user1.age = 30
    database.insert(user1)

    let user2 = User()
    user2.name = "王五"
    user2.age = 28
    database.insert(user2)

    return true // 返回true提交，false回滚
}

// 原始SQL查询
let result = db.executeQuery("SELECT * FROM User WHERE age > ?", params: [25])

// 批量插入
let users = [
    User(name: "用户1", age: 20),
    User(name: "用户2", age: 22),
    User(name: "用户3", age: 24)
]
db.batchInsert(users)

// 数据库迁移
db.migrate(from: 1, to: 2) { database, version in
    if version == 1 {
        database.executeUpdate("ALTER TABLE User ADD COLUMN phone TEXT")
    }
}
```

### Combine支持

```swift
import Combine
import LWSQLCipherDB_swift

class UserRepository {
    private let db: LWSQLCipherDB
    private var cancellables = Set<AnyCancellable>()

    init(db: LWSQLCipherDB) {
        self.db = db
    }

    func fetchUsers() -> AnyPublisher<[User], Error> {
        Future { promise in
            let users = self.db.query(User.self)
            promise(.success(users))
        }
        .eraseToAnyPublisher()
    }
}
```

## 与Objective-C版本的区别

- Swift版本要求iOS 13.0+（Objective-C版本支持iOS 8.0+）
- Swift版本提供了Combine和async/await支持
- Swift版本使用现代Swift语法和属性包装器
- 提供更类型安全的API
- 支持Swift泛型和Result类型

## 安全性

- 使用SQLCipher进行数据库加密
- 支持AES-256加密算法
- 密码保护的数据库文件
- 防止SQL注入攻击

## 注意事项

- 如果你的项目同时使用Objective-C和Swift，可以同时安装`LWSQLCipherDB`和`LWSQLCipherDB_swift`
- Swift版本与Objective-C版本可以共存，互不影响
- 请妥善保管数据库密码，密码丢失将无法访问数据
- 建议定期备份数据库文件

## 许可证

LWSQLCipherDB_swift遵循MIT许可证。详见LICENSE文件。
