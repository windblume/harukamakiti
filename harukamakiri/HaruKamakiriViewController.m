//
//  HaruKamakiriViewController.m
//  harukamakiri
//
//  Created by yosuke on 2013/05/08.
//  Copyright (c) 2013年 yosuke. All rights reserved.
//

#import "HaruKamakiriViewController.h"

@interface HaruKamakiriViewController ()

@end

//TwitterClientの実装
@implementation HaruKamakiriViewController{
    
    UIRefreshControl *refreshControl;
}

//====================
//ユーティリティ
//====================
//データ→文字列
- (NSString*)data2str:(NSData*)data {
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

//アラートの表示
- (void)showAlert:(NSString*)title text:(NSString*)text {
    UIAlertView *alert=[[UIAlertView alloc] initWithTitle:title
                                                  message:text
                                                 delegate:nil
                                        cancelButtonTitle:@"OK"
                                        otherButtonTitles:nil];
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
/*
//イメージビューの生成
- (UIImageView*)makeImageView:(CGRect)rect image:(UIImage*)image {
    UIImageView* imageView=[[UIImageView alloc] init];
    [imageView setImage:image];
    [imageView setFrame:rect];
    return imageView;
}
*/

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
                                               [self showAlert:@"アカウント未登録です。" text:@"Twitterアカウントが登録されていません。設定内でTwitterアカウントを登録してください。"];
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
                                           returningResponse:nil
                                                       error:nil];
        
        //テーブル更新
        dispatch_async(dispatch_get_main_queue(),^{
            UIImage* icon=[[UIImage alloc] initWithData:data];
            status.icon=icon;
            [self._tableView reloadData];
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
//                NSLog(@"refresh %d", i);
            }
            
            //テーブル更新
            dispatch_async(dispatch_get_main_queue(),^{
            [self._tableView reloadData];
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
    [twitterCtl setInitialText:@" #harukamakiri"];
    [self presentViewController:twitterCtl animated:YES completion:nil];
}


//ひっぱってリロード
- (void)refresh
{
    NSLog(@"refresh");
    [_items removeAllObjects];
    [self timeline];

//    [refreshControl endRefreshing];
    [NSTimer scheduledTimerWithTimeInterval:5.f target:self selector:@selector(endRefresh) userInfo:nil repeats:NO];
}


//====================
//セルの表示関係
//====================
//行数の取得
- (NSInteger)tableView:(UITableView*)tableView
 numberOfRowsInSection:(NSInteger)section {
    return _items.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TweetCell"];
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    //    if (_items.count<=indexPath.row) return cell;
    if (cell == nil) {
        cell = [[UITableViewCell alloc]
                initWithStyle:UITableViewCellStyleDefault
                reuseIdentifier:@"TweetCell"];
    }
    
    Status *status=_items[indexPath.row];

/*アイコン*/
    UIImageView *icon = (UIImageView*)[cell viewWithTag:102];
    icon.image = status.icon;
//    [cell.contentView addSubview:icon];
    
/*名前ラベル*/
    UILabel *Namelbl = (UILabel*)[cell viewWithTag:100];
    Namelbl.text = status.name;
    [cell.contentView addSubview:Namelbl];

/*ツイートラベル*/
/*    float w=(_portrait)?
    self.view.window.screen.bounds.size.width-70:
    self.view.window.screen.bounds.size.height-70;
    CGSize size=[status.text sizeWithFont:[UIFont systemFontOfSize:14]
                        constrainedToSize:CGSizeMake(w,1024)
                            lineBreakMode:NSLineBreakByCharWrapping];

    UILabel* lblText=[self makeLabel:CGRectMake(60,30,w,size.height)
                                text:status.text font:[UIFont systemFontOfSize:14]];
    [cell.contentView addSubview:lblText];
*/

    UILabel *Tweetlbl = (UILabel *)[cell viewWithTag:101];
    [Tweetlbl setFrame:CGRectMake(60,30,250,300)];
    [Tweetlbl setText:status.text];
    [Tweetlbl setFont:[UIFont systemFontOfSize:14]];
    [Tweetlbl setTextColor:[UIColor blackColor]];
    [Tweetlbl setBackgroundColor:[UIColor clearColor]];
    [Tweetlbl setTextAlignment:NSTextAlignmentLeft];
    [Tweetlbl setNumberOfLines:0];
    [Tweetlbl setLineBreakMode:NSLineBreakByCharWrapping];
/*
//    [Tweetlbl setLineBreakMode:NSLineBreakByCharWrapping];
//    Tweetlbl.frame = CGRectMake(60, 30, 100, 300);
    [Tweetlbl setFrame:CGRectMake(60,30,100,300)];
//    [orange setFrame:CGRectMake( 32.0f, orange.center.y+20.0f , 32.0f, 32.0f)];
    Tweetlbl.numberOfLines = 0;
    Tweetlbl.text = status.text;
*/
    [Tweetlbl sizeToFit];

    NSLog(@"%f",Tweetlbl.frame.origin.x);
    //    Tweetlbl = CGSizeMake(w, size.height);    
    [cell.contentView addSubview:Tweetlbl];

    return cell;
}

//====================
//UIのデリゲート
//====================

//行の高さの取得
- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath {
    Status* status=_items[indexPath.row];
    float w=(_portrait)?
    self.view.window.screen.bounds.size.width-60:
    self.view.window.screen.bounds.size.height-70;
    CGSize size=[status.text sizeWithFont:[UIFont systemFontOfSize:14]
                        constrainedToSize:CGSizeMake(w,1024)
                            lineBreakMode:NSLineBreakByCharWrapping];
    float height=size.height+48;
    return (height<60)?60:height;
}
/*
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
    Status* status=[_items objectAtIndex:indexPath.row];
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
*/

//回転完了後に呼ばれる
-(void)didRotateFromInterfaceOrientation:
(UIInterfaceOrientation)fromInterfaceOrientation {
    UIInterfaceOrientation orientation=
    [[UIApplication sharedApplication] statusBarOrientation];
    _portrait=UIInterfaceOrientationIsPortrait(orientation);
    
    //テーブル更新
    dispatch_async(dispatch_get_main_queue(),^{
        [self._tableView reloadData];
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
    //self.title=@"Twitterクライアント";
    UIInterfaceOrientation orientation=[[UIApplication sharedApplication] statusBarOrientation];
    _portrait=UIInterfaceOrientationIsPortrait(orientation);
        
    //要素
    _items = [NSMutableArray array];
    
    //Twitterアカウントの取得(2)
    [self initTwitterAccount];
    
/*
    //ひっぱってリロード
    refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];
    [__tableView addSubview:refreshControl];
*/    

    self.view.exclusiveTouch = YES;    
    NSLog(@"ViewDidLoad");

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//リフレッシュボタンの処理
 - (IBAction)RefreshTL:(id)sender {
//     [self initTwitterAccount];
     //_items初期化 Statusに格納している要素をすべて削除
     [_items removeAllObjects];
     [self timeline];
 }

//アクション(ツイート)ボタンの処理
 - (IBAction)TweetTL:(id)sender {
//     [self initTwitterAccount];
     [self twit];
 }

@end