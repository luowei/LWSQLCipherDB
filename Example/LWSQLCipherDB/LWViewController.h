//
//  LWViewController.h
//  LWSQLCipherDB
//
//  Created by luowei on 05/07/2019.
//  Copyright (c) 2019 luowei. All rights reserved.
//

@import UIKit;
#import <LWSQLCipherDB/LWDBModel.h>

@interface LWViewController : UIViewController

@end




@interface User : LWDBModel
/** 账号 */
@property (nonatomic, copy)     NSString                    *account;
/** 名字 */
@property (nonatomic, copy)     NSString                    *name;
/** 性别 */
@property (nonatomic, copy)     NSString                    *sex;
/** 头像地址 */
@property (nonatomic, copy)     NSString                    *portraitPath;
/** 手机号码 */
@property (nonatomic, copy)     NSString                    *moblie;
/** 简介 */
@property (nonatomic, copy)     NSString                    *descn;
/** 年龄 */
@property (nonatomic, assign)  int                          age;
/** 身高 */

@property (nonatomic, assign)   int                        height;

//这个字段在数据库中不会创建
@property (nonatomic, assign)   int                        noField;

@end
