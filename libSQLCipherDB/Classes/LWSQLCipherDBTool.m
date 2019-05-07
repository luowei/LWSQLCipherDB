//
//  LWSQLCipherDBTool.m
//  LKFMDB_Demo
//
//  Created by luowei on 16/3/21.
//  Copyright © 2017年 luowei. All rights reserved.
//  github http://wodedata.com

#import "LWSQLCipherDBTool.h"

@interface LWSQLCipherDBTool ()
@property(nonatomic, retain) FMDatabaseQueue *dbQueue;
@end

static LWSQLCipherDBTool *_instance = nil;

@implementation LWSQLCipherDBTool

+ (instancetype)shareInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[super allocWithZone:NULL] init];
    });
    return _instance;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    return [LWSQLCipherDBTool shareInstance];
}

- (instancetype)copyWithZone:(struct _NSZone *)zone {
    return [LWSQLCipherDBTool shareInstance];
}

+ (NSString *)dbPath {
    return [self dbPathWithDirectoryName:nil];
}

+ (NSString *)dbPathWithDirectoryName:(NSString *)directoryName {
    NSString *docsdir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSFileManager *filemanage = [NSFileManager defaultManager];
    if (directoryName == nil || directoryName.length == 0) {
        docsdir = [docsdir stringByAppendingPathComponent:@"LWDB"];
    } else {
        docsdir = [docsdir stringByAppendingPathComponent:directoryName];
    }
    BOOL isDir;
    BOOL exit = [filemanage fileExistsAtPath:docsdir isDirectory:&isDir];
    if (!exit || !isDir) {
        [filemanage createDirectoryAtPath:docsdir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSString *dbpath = [docsdir stringByAppendingPathComponent:@"lwdb"];

    NSLog(@"dbpath %@", dbpath);
    return dbpath;
}


- (FMDatabaseQueue *)dbQueue {
    if (_dbQueue == nil) {
        _dbQueue = [[FMDatabaseQueue alloc] initWithPath:[self.class dbPath]];
    }
    return _dbQueue;
}

- (BOOL)changeDBWithDirectoryName:(NSString *)directoryName {
    if (_instance.dbQueue) {
        _instance.dbQueue = nil;
    }
    _instance.dbQueue = [[FMDatabaseQueue alloc] initWithPath:[LWSQLCipherDBTool dbPathWithDirectoryName:directoryName]];

    int numClasses;
    Class *classes = NULL;
    numClasses = objc_getClassList(NULL, 0);

    if (numClasses > 0) {
        classes = (__unsafe_unretained Class *) malloc(sizeof(Class) * numClasses);
        numClasses = objc_getClassList(classes, numClasses);
        for (int i = 0; i < numClasses; i++) {
            if (class_getSuperclass(classes[i]) == [LWSQLCipherDBTool class]) {
                id class = classes[i];
                [class performSelector:@selector(createTable) withObject:nil];
            }
        }
        free(classes);
    }

    return YES;
}


@end


@implementation FMDatabase (LWDBSwizzling)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [FMDatabase lwdb_swizzleMethod:@selector(secretKey) withMethod:@selector(mySecretKey)];
    });
}

- (NSString *)mySecretKey {
    return @"luowei.wodedata.com";
}

@end


@implementation NSObject (LWDBSwizzling)

+ (BOOL)lwdb_swizzleMethod:(SEL)origSel withMethod:(SEL)altSel {
    Method origMethod = class_getInstanceMethod(self, origSel);
    Method altMethod = class_getInstanceMethod(self, altSel);
    if (!origMethod || !altMethod) {
        return NO;
    }
    class_addMethod(self, origSel, class_getMethodImplementation(self, origSel), method_getTypeEncoding(origMethod));
    class_addMethod(self, altSel, class_getMethodImplementation(self, altSel), method_getTypeEncoding(altMethod));
    method_exchangeImplementations(class_getInstanceMethod(self, origSel), class_getInstanceMethod(self, altSel));
    return YES;
}

+ (BOOL)lwdb_swizzleClassMethod:(SEL)origSel withMethod:(SEL)altSel {
    return [object_getClass((id) self) lwdb_swizzleMethod:origSel withMethod:altSel];
}

@end