//
//  LWDBSQLState.m
//  LKFMDB_Demo
//
//  Created by luowei on 16/3/22.
//  Copyright © 2017年 luowei. All rights reserved.
//
//  github http://wodedata.com

#import "LWDBSQLState.h"

@interface LWDBSQLState ()
@property(nonatomic, copy) NSString *queryStr;


@end


@implementation LWDBSQLState

- (LWDBSQLState *)object:(Class)obj
                    type:(QueryType)type
                     key:(id)key
                     opt:(NSString *)opt
                   value:(id)value {

    LWDBModel *model = [obj new];
    //判断属性名和属性类型  text必须加‘’  确定是否‘’
    for (int i = 0; i < model.propertyNames.count; i++) {

        if ([key isEqual:model.propertyNames[i]]) {

            if ([model.propertyNames[i] isEqualToString:model.columeNames[i]]) {
                [self ifEqualTOSQLTEXT:model.columeTypes[i] Key:key opt:opt value:value condition:type];
                break;
            } else {
                key = model.columeNames[i];
                [self ifEqualTOSQLTEXT:model.columeTypes[i] Key:key opt:opt value:value condition:type];
                break;
            }
        }
    }
    return self;
}

- (NSString *)sqlOptionStr {
    return _queryStr;
}


#pragma mark util method

- (void)ifEqualTOSQLTEXT:(NSString *)propertyType
                     Key:(id)key
                     opt:(NSString *)opt
                   value:(id)value
               condition:(QueryType)condition {

    if ([propertyType isEqualToString:SQLTEXT]) {
        _queryStr = [NSString stringWithFormat:@" %@ %@ %@ '%@'", [self typeToString:condition], key, opt, value];

    } else {
        _queryStr = [NSString stringWithFormat:@" %@ %@ %@ %@", [self typeToString:condition], key, opt, value];

    }
}

- (NSString *)typeToString:(QueryType)type {
    switch (type) {
        case WHERE:
            return @"WHERE";
            break;
        case AND:
            return @"AND";
            break;
        case OR:
            return @"OR";
            break;
        default:
            break;
    }
}


@end
