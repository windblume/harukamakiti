//
//  harukamakiriViewController.h
//  harukamakiri
//
//  Created by yosuke on 2013/05/06.
//  Copyright (c) 2013年 yosuke. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Social/Social.h>
#import <Accounts/Accounts.h>
#import "Status.h"

@interface HHharukamakiriViewController : UIViewController<UITableViewDelegate,UITableViewDataSource,UITextFieldDelegate>
{
    //UI
    IBOutlet UITableView* _tableView;
    BOOL                  _portrait;
    
    //変数
    ACAccountStore* _accountStore;
    ACAccount*      _account;
    NSMutableArray* _items;
}

- (IBAction)TL_Refresh:(id)sender;
- (IBAction)Tweet_TL:(id)sender;

@end
