//
//  LWSQLCipherDBTool.h
//  LKFMDB_Demo
//
//  Created by luowei on 16/3/21.
//  Copyright © 2017年 luowei. All rights reserved.
//  github http://wodedata.com

#import <Foundation/Foundation.h>
#import "FMDB.h"
#import <objc/runtime.h>
#import "LWDBColumnDes.h"
#import "LWDBSQLState.h"

@interface LWSQLCipherDBTool : NSObject

@property(nonatomic, retain, readonly) FMDatabaseQueue *dbQueue;

/**
 *  单列 操作数据库保证唯一
 */
+ (instancetype)shareInstance;

/**
 *  数据库路径
 */
+ (NSString *)dbPath;

/**
 *  切换数据库
 */
- (BOOL)changeDBWithDirectoryName:(NSString *)directoryName;

@end




@interface NSObject (LWDBSwizzling)

+ (BOOL)lwdb_swizzleMethod:(SEL)origSel withMethod:(SEL)altSel;

+ (BOOL)lwdb_swizzleClassMethod:(SEL)origSel withMethod:(SEL)altSel ;

@end
