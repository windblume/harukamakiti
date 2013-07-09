//
//  Status.m
//  harukamakiri
//
//  Created by yosuke on 2013/05/06.
//  Copyright (c) 2013年 yosuke. All rights reserved.
//

#import "Status.h"
//Statusの実装
@implementation Status

//プロパティ
@synthesize name   =_name;
@synthesize text   =_text;
@synthesize iconURL=_iconURL;
@synthesize icon   =_icon;

//初期化
- (id)init {
    if (self=[super init]) {
        _name   =nil;
        _text   =nil;
        _iconURL=nil;
        _icon   =nil;
    }
    return self;
}

 
 
/*メモリ解放
- (void)dealloc {
    [_name release];
    [_text release];
    [_icon release];
    [_iconURL release];
    [super dealloc];
}
*/
@end
