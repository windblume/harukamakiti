//
//  Status.h
//  harukamakiri
//
//  Created by yosuke on 2013/05/06.
//  Copyright (c) 2013年 yosuke. All rights reserved.
//

#import <Foundation/Foundation.h>

//Twitter Status
@interface Status : NSObject
/*{
    NSString* name;   //名前
    NSString* text;   //Tweet
    NSString* iconURL;//アイコンURL
    UIImage*  icon;   //アイコン
}
 */
//実装予定プロパティ
@property (nonatomic,strong)NSString *name;
@property (nonatomic,strong)NSString *text;
@property (nonatomic,strong)NSString *iconURL;
@property (nonatomic,strong)UIImage  *icon;

@end
