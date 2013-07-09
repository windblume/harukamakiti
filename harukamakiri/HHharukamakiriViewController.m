//
//  harukamakiriViewController.m
//  harukamakiri
//
//  Created by yosuke on 2013/05/06.
//  Copyright (c) 2013年 yosuke. All rights reserved.
//

#import "HHharukamakiriViewController.h"

@interface HHharukamakiriViewController ()

@end

//TwitterClientの実装
@implementation HHharukamakiriViewController

//====================
//ユーティリティ
//====================
//データ→文字列
- (NSString*)data2str:(NSData*)data {
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

//アラートの表示
- (void)showAlert:(NSString*)title text:(NSString*)text {
    UIAlertView* alert=[[UIAlertView alloc]
                         initWithTitle:title message:text delegate:nil
                         cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}

//インジケーターの指定
- (void)setIndicator:(BOOL)indicator {
    [UIApplication sharedApplication].
    networkActivityIndicatorVisible=indicator;
}

//ラベルの生成
- (UILabel*)makeLabel:(CGRect)rect text:(NSString*)text font:(UIFont*)font {
    UILabel* label=[[UILabel alloc] init];
    [label setFrame:rect];
    [label setText:text];
    [label setFont:font];
    [label setTextColor:[UIColor blackColor]];
    [label setBackgroundColor:[UIColor clearColor]];
    [label setTextAlignment:NSTextAlignmentLeft];
    [label setNumberOfLines:0];
    [label setLineBreakMode:NSLineBreakByCharWrapping];
    return label;
}

//イメージビューの生成
- (UIImageView*)makeImageView:(CGRect)rect image:(UIImage*)image {
    UIImageView* imageView=[[UIImageView alloc] init];
    [imageView setImage:image];
    [imageView setFrame:rect];
    return imageView;
}

//====================
//Twitterのリクエスト
//====================
//Twitterアカウントの取得(2)
- (void)initTwitterAccount {
    _account=nil;
    _accountStore=[[ACAccountStore alloc] init];
    ACAccountType* twitterType=[_accountStore
                                accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    [_accountStore requestAccessToAccountsWithType:twitterType
                                           options:nil completion:^(BOOL granted,NSError* e) {
                                               if (granted) {
                                                   NSArray* accounts=[_accountStore accountsWithAccountType:twitterType];
                                                   if (accounts.count>0) {
                                                       _account=accounts[0];
                                                       [self timeline];
                                                       return;
                                                   }
                                               }
                                               [self showAlert:@"" text:@"Twitterアカウントが登録されていません"];
                                           }];
}

//アイコンの読み込み
- (void)loadIcon:(Status*)status {
    //通信によるアイコン読み込み
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        NSURLRequest* request=[NSURLRequest
                               requestWithURL:[NSURL URLWithString:status.iconURL]
                               cachePolicy:NSURLRequestUseProtocolCachePolicy
                               timeoutInterval:30.0];
        NSData* data=[NSURLConnection sendSynchronousRequest:request
                                           returningResponse:nil error:nil];
        
        //テーブル更新
        dispatch_async(dispatch_get_main_queue(),^{
            UIImage* icon=[[UIImage alloc] initWithData:data];
            status.icon=icon;
            [_tableView reloadData];
        });
    });
}

//タイムラインの取得
- (void)timeline {
    [self setIndicator:YES];
    
    //通信によるタイムライン読み込み(2)
    NSURL* url=[NSURL URLWithString:
                @"http://api.twitter.com/1/statuses/home_timeline.json"];
    NSDictionary* params=@{@"count": @"20"};
    SLRequest* timeline=[SLRequest
                         requestForServiceType:SLServiceTypeTwitter
                         requestMethod:SLRequestMethodGET
                         URL:url parameters:params];
    timeline.account=_account;
    [timeline performRequestWithHandler:^(NSData* responseData,
                                          NSHTTPURLResponse* urlResponse,NSError* error) {
        //JSONのパース(3)
        NSError* jsonError=nil;
        NSArray* statuses=[NSJSONSerialization JSONObjectWithData:responseData
                                                          options:0 error:&jsonError];
        
        //エラー表示
        if (error!=nil) {
            [self showAlert:@"" text:@"通信失敗しました"];
        } else if (jsonError!=nil) {
            [self showAlert:@"" text:@"パースに失敗しました"];
        } else {
            //JSONをパースしたデータをStatusの配列に変換(4)
            for (int i=0;i<statuses.count;i++) {
                NSDictionary* status=statuses[i];
                NSDictionary* user  =status[@"user"];
                Status* item=[[Status alloc] init];
                item.text   =status[@"text"];
                item.name   =user[@"screen_name"];
                item.iconURL=user[@"profile_image_url"];
                [self loadIcon:item];
                [_items addObject:item];
            }
            
            //テーブル更新
            dispatch_async(dispatch_get_main_queue(),^{
                [_tableView reloadData];
            });
        }
        //通信完了
        [self setIndicator:NO];
    }];
}

//つぶやきの送信(5)
- (void)twit {
    SLComposeViewController* twitterCtl=[SLComposeViewController
                                         composeViewControllerForServiceType:SLServiceTypeTwitter];
    [self presentViewController:twitterCtl animated:YES completion:nil];
}


/*   メモリ解放
- (void)dealloc {
    [_tableView release];
    [_accountStore release];
    [_account release];
    [_items release];
    [super dealloc];
}
*/

//====================
//UIのデリゲート
//====================
//行数の取得
- (NSInteger)tableView:(UITableView*)tableView
 numberOfRowsInSection:(NSInteger)section {
    return _items.count;
}

//行の高さの取得
- (CGFloat)tableView:(UITableView*)tableView
heightForRowAtIndexPath:(NSIndexPath*)indexPath {
    Status* status=_items[indexPath.row];
    float w=(_portrait)?
    self.view.window.screen.bounds.size.width-70:
    self.view.window.screen.bounds.size.height-70;
    CGSize size=[status.text sizeWithFont:[UIFont systemFontOfSize:14]
                        constrainedToSize:CGSizeMake(w,1024)
                            lineBreakMode:NSLineBreakByCharWrapping];
    float height=30+size.height+10;
    return (height<60)?60:height;
}

//行のセルの取得
- (UITableViewCell*)tableView:(UITableView*)tableView
        cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    //テーブルのセルの生成
    UITableViewCell* cell=[[UITableViewCell alloc]
                            initWithStyle:UITableViewCellStyleSubtitle
                            reuseIdentifier:@"table_cell"];
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    if (_items.count<=indexPath.row) return cell;
    
    //セルの編集
    Status* status=_items[indexPath.row];
    UIImageView* imgIcon=[self makeImageView:
                          CGRectMake(10,10,40,40) image:status.icon];
    [cell.contentView addSubview:imgIcon];
    UILabel* lblName=[self makeLabel:CGRectMake(60,10,250,16)
                                text:status.name font:[UIFont boldSystemFontOfSize:16]];
    [cell.contentView addSubview:lblName];
    float w=(_portrait)?
    self.view.window.screen.bounds.size.width-70:
    self.view.window.screen.bounds.size.height-70;
    CGSize size=[status.text sizeWithFont:[UIFont systemFontOfSize:14]
                        constrainedToSize:CGSizeMake(w,1024)
                            lineBreakMode:NSLineBreakByCharWrapping];
    UILabel* lblText=[self makeLabel:CGRectMake(60,30,w,size.height)
                                text:status.text font:[UIFont systemFontOfSize:14]];
    [cell.contentView addSubview:lblText];
    return cell;
}

//回転完了後に呼ばれる
-(void)didRotateFromInterfaceOrientation:
(UIInterfaceOrientation)fromInterfaceOrientation {
    UIInterfaceOrientation orientation=
    [[UIApplication sharedApplication] statusBarOrientation];
    _portrait=UIInterfaceOrientationIsPortrait(orientation);
    
    //テーブル更新
    dispatch_async(dispatch_get_main_queue(),^{
        [_tableView reloadData];
    });
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//====================
//初期化
//====================
//ビューがロードされた時の処理
- (void)viewDidLoad {
    [super viewDidLoad];
    
    //UI
    self.title=@"Twitterクライアント";
    UIInterfaceOrientation orientation=[[UIApplication sharedApplication] statusBarOrientation];
    _portrait=UIInterfaceOrientationIsPortrait(orientation);
    
    
    //要素
    _items=[NSMutableArray array];
    
    //Twitterアカウントの取得(2)
    [self initTwitterAccount];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//リフレッシュボタンの処理
- (IBAction)TL_Refresh:(id)sender {
    [self timeline];
}

//アクション(ツイート)ボタンの処理
- (IBAction)Tweet_TL:(id)sender {
    [self twit];
}
@end
