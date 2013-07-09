//
//  HaruKamakiriViewController.h
//  harukamakiri
//
//  Created by yosuke on 2013/05/08.
//  Copyright (c) 2013年 yosuke. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Social/Social.h>
#import <Accounts/Accounts.h>
#import "Status.h"

@interface HaruKamakiriViewController : UIViewController<UITableViewDelegate,UITableViewDataSource,UITextFieldDelegate,UIAlertViewDelegate>
//UITableViewController
{
    //UI
    BOOL                  _portrait;
    
    //変数
    ACAccountStore* _accountStore;
    ACAccount*      _account;
    NSMutableArray* _items;     //tweetコンテンツ
}

@property (nonatomic, strong) NSMutableArray *Status;
@property (strong, nonatomic) IBOutlet UITableView *_tableView;

- (IBAction)RefreshTL:(id)sender;
- (IBAction)TweetTL:(id)sender;

@end
