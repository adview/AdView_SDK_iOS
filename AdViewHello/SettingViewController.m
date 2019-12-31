//
//  SettingViewController.m
//  AdViewHello
//
//  Created by AdView on 2017/6/22.
//
//

#import "SettingViewController.h"
#import "KeyViewController.h"
#import "AdViewExtTool.h"
#import "ReplacementViewController.h"
#import "AutoTestViewController.h"

@interface SettingViewController ()<UITableViewDelegate,UITableViewDataSource>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray *textArray;
@end

@implementation SettingViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    UIImageView *view = [self.navigationController.navigationBar viewWithTag:10000];
    view.alpha = 1;
    [self.tableView reloadData];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"设置";
    _textArray = @[@"测试服务器",@"html设置",@"返回数据替换功能",@"替换XS字段功能",@"自动测试功能"];
    [self addBackItem];
    [self addTableView];
}

- (void)addBackItem {
    UIImageView *imgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"backImage"]];
    CGFloat y = 10;
    CGFloat height = 44 - y * 2;
    CGFloat width = 25*height/44.f;
    imgView.frame = CGRectMake(13, y, width, height);
    imgView.userInteractionEnabled = YES;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backClick)];
    [imgView addGestureRecognizer:tap];
    imgView.tag = 10000;
    [self.navigationController.navigationBar addSubview:imgView];
}

- (void)backClick {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)addTableView {
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, ScreenHeight) style:UITableViewStyleGrouped];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self setExtraCellLineHidden:self.tableView];
    [self.view addSubview:_tableView];
}

- (void)setExtraCellLineHidden: (UITableView *)tableView
{
    UIView *view = [UIView new];
    view.backgroundColor = [UIColor clearColor];
    [tableView setTableFooterView:view];
}

#pragma mark - action
//设置界面 开关
- (void)valueChange:(id)sender
{
    UISwitch *sch = (UISwitch*)sender;
    NSString *string = USE_TEST_SERVER_KEY;
    if (sch.tag == 1)
    {
        string = @"html";
    }
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSString stringWithFormat:@"%d",sch.on] forKey:string];
}

#pragma mark tableview delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 5;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return 1;
        case 1:
            return 2;
        case 2:
            return 2;
        case 3:
            return 1;
        case 4:
            return 1;
    }
    return _textArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *reusableString = @"cell";
    UITableViewCellStyle style = UITableViewCellStyleValue1;
    if (indexPath.section == 0) {
        reusableString = @"cell0";
        style = UITableViewCellStyleSubtitle;
    }else if (indexPath.section == 1) {
        reusableString = @"cell1";
        style = UITableViewCellStyleDefault;
    }else if (indexPath.section == 4) {
        reusableString = @"cell4";
        style = UITableViewCellStyleDefault;
    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reusableString];
    if (nil == cell) {
        cell = [[UITableViewCell alloc] initWithStyle:style reuseIdentifier:reusableString];
        if (indexPath.section == 1) {
            UISwitch *sch = [[UISwitch alloc] initWithFrame:CGRectMake((ScreenWidth - 50 - 13), 7.5, 30, 50)];
            [cell.contentView addSubview:sch];
        }
    }
    
    if (indexPath.section == 0) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *key = [defaults objectForKey:@"currentKey"];
        if (key) {
            cell.textLabel.text = key;
            cell.detailTextLabel.text = @"当前使用key";
        }else {
            BOOL isOn = [[defaults objectForKey:USE_TEST_SERVER_KEY] boolValue];
            NSString *arrStr = @"keys";
            if (isOn) {
                arrStr = @"testKeys";
            }
            NSArray *keyArr = [defaults objectForKey:arrStr];
            if (keyArr && keyArr.count) {
                cell.textLabel.text = [keyArr firstObject];
                cell.detailTextLabel.text = @"当前使用key";
            }else {
                cell.textLabel.text = @"添加key";
                cell.detailTextLabel.text = @"";
            }
        }
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }else if (indexPath.section == 1) {
        cell.textLabel.text = [self.textArray objectAtIndex:indexPath.row];
        
        for (UIView *view in cell.contentView.subviews) {
            if ([view isKindOfClass:[UISwitch class]]) {
                UISwitch *sch = (UISwitch*)view;
                NSString *string = USE_TEST_SERVER_KEY;
                if (indexPath.row == 1) {
                    string = @"html";
                }
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                BOOL isOn = [[defaults objectForKey:string] boolValue];
                [sch setOn:isOn];
                [sch addTarget:self action:@selector(valueChange:) forControlEvents:UIControlEventValueChanged];
                sch.tag = indexPath.row;
            }
        }
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }else if (indexPath.section == 2){
        cell.textLabel.text = [self.textArray objectAtIndex:(indexPath.section + indexPath.row)];
        NSString *statusString = @"关闭";
        if (([AdViewExtTool sharedTool].replaceXSFuction && indexPath.row == 1) || ([AdViewExtTool sharedTool].replaceResponseFuction && indexPath.row == 0)) {
            statusString = @"打开";
        }
        cell.detailTextLabel.text = statusString;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }else if (indexPath.section == 4) {
        cell.textLabel.text = [AdViewExtTool getIDA];
    }else {
        cell.textLabel.text = [self.textArray lastObject];
        cell.detailTextLabel.text = @"";
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 0) {
        KeyViewController *kvc = [[KeyViewController alloc] init];
        [self.navigationController pushViewController:kvc animated:YES];
    }else if (indexPath.section == 2) {
        ReplacementString type = Replacement_ALL;
        if (indexPath.row == 1) {
            type = Replacement_XS;
        }
        ReplacementViewController *rvc = [[ReplacementViewController alloc] initWithType:type];
        [self.navigationController pushViewController:rvc animated:YES];
    }else if (indexPath.section == 3) {
        AutoTestViewController *avc = [[AutoTestViewController alloc] init];
        [self.navigationController pushViewController:avc animated:YES];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        return 60;
    }
    return 45;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 30;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0.1f;
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return nil;
}

- (BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 4) {
        return YES;
    }
    return NO;
}

- (BOOL)tableView:(UITableView *)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
    if (action == @selector(copy:)) {
        return YES;
    }
    return NO;
}

- (void)tableView:(UITableView *)tableView performAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
    if (action == @selector(copy:)) {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        [UIPasteboard generalPasteboard].string = cell.textLabel.text;
    }
}

#pragma mark -

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
