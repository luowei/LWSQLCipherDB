# LWSQLCipherDB

[![CI Status](https://img.shields.io/travis/luowei/LWSQLCipherDB.svg?style=flat)](https://travis-ci.org/luowei/LWSQLCipherDB)
[![Version](https://img.shields.io/cocoapods/v/LWSQLCipherDB.svg?style=flat)](https://cocoapods.org/pods/LWSQLCipherDB)
[![License](https://img.shields.io/cocoapods/l/LWSQLCipherDB.svg?style=flat)](https://cocoapods.org/pods/LWSQLCipherDB)
[![Platform](https://img.shields.io/cocoapods/p/LWSQLCipherDB.svg?style=flat)](https://cocoapods.org/pods/LWSQLCipherDB)

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

## Requirements

## Installation

LWSQLCipherDB is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'LWSQLCipherDB'
```

## Author

luowei, luowei@wodedata.com

## License

LWSQLCipherDB is available under the MIT license. See the LICENSE file for more info.
