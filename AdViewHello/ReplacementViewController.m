//
//  ReplacementViewController.m
//  AdViewHello
//
//  Created by AdView on 2017/6/26.
//
//

#import "ReplacementViewController.h"
#import "AdViewExtTool.h"

@interface ReplacementViewController ()<UITableViewDelegate,UITableViewDataSource,UITextViewDelegate>
@property (nonatomic, assign) ReplacementString type;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, assign) CGFloat footerHeight;
@end

@implementation ReplacementViewController

- (instancetype)initWithType:(ReplacementString)type {
    if (self = [super init]) {
        self.type = type;
        self.footerHeight = 40;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"替换数据";
    // Do any additional setup after loading the view.
    UIImageView *view = [self.navigationController.navigationBar viewWithTag:10000];
    view.alpha = 0;
    [self addTableView];
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

#pragma mark tableview delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *reusableString = @"cell";
    UITableViewCellStyle style = UITableViewCellStyleDefault;
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reusableString];
    if (nil == cell) {
        cell = [[UITableViewCell alloc] initWithStyle:style reuseIdentifier:reusableString];
        UISwitch *sch = [[UISwitch alloc] initWithFrame:CGRectMake((ScreenWidth - 50 - 13), 7.5, 30, 50)];
        sch.tag = 101010;
        [cell.contentView addSubview:sch];
    }
    
    UISwitch *sch = [cell.contentView viewWithTag:101010];
    [sch addTarget:self action:@selector(valueChange:) forControlEvents:UIControlEventValueChanged];
    switch (_type) {
        case Replacement_XS:
            [sch setOn:[AdViewExtTool sharedTool].replaceXSFuction];
            cell.textLabel.text = @"替换XS数据";
            break;
        case Replacement_ALL:
            cell.textLabel.text = @"替换所有数据";
            [sch setOn:[AdViewExtTool sharedTool].replaceResponseFuction];
            break;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 45;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 30;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    switch (_type) {
    case Replacement_XS:
            if ([AdViewExtTool sharedTool].replaceXSFuction) {
                self.footerHeight = 400;
            };
        break;
    case Replacement_ALL:
            if ([AdViewExtTool sharedTool].replaceResponseFuction) {
                self.footerHeight = 400;
            };
        break;
    }
    return self.footerHeight;
}

- (UIView*)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    UIView *view = [[UIView alloc] init];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(13, 0, ScreenWidth - 13, 40)];
    NSString *string = @"替换所有数据功能用于替换请求广告返回的所有广告数据";
    if (_type == Replacement_XS) {
        string = @"替换xs字段功能用于替换请求广告返回数据中的xs字段";
    }
    label.text = string;
    label.font = [UIFont systemFontOfSize:14];
    label.textColor = [UIColor lightGrayColor];
    if (self.footerHeight > 40) {
        label.text = @"功能已开启";
        UITextView *textView = [[UITextView alloc] initWithFrame:CGRectMake(13, 40, ScreenWidth - 26, 360)];
        textView.text = [self getFileContent];
        textView.backgroundColor = [UIColor clearColor];
        textView.textColor = [UIColor lightGrayColor];
        textView.delegate = self;
        textView.layer.borderColor = [UIColor grayColor].CGColor;
        textView.layer.borderWidth = 1.0f;
        [view addSubview:textView];
    }
    [view addSubview:label];
    return view;
}

#pragma mark - other action
- (NSString*)getFileContent
{
    NSString *fileName = @"test_xs.txt";
    if (_type == Replacement_ALL) {
        fileName = @"test_all.txt";
    }
    NSString *sPath = [[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] stringByAppendingPathComponent:fileName];
    BOOL bExist = [self isFileExists:sPath];
    if (bExist) {
        NSString *strXS = [NSString stringWithContentsOfFile:sPath encoding:NSUTF8StringEncoding error:nil];
        if (nil != strXS) {
            return strXS;
        }
    }
    return @"输入需要替换的数据";
}

#pragma mark - action
- (void)valueChange:(id)sender {
    UISwitch *sch = (UISwitch*)sender;
    switch (_type) {
        case Replacement_XS:
            [AdViewExtTool sharedTool].replaceXSFuction = sch.on;
            break;
        case Replacement_ALL:
            [AdViewExtTool sharedTool].replaceResponseFuction = sch.on;
            break;
    }
    if (!sch.on) {
        self.footerHeight = 40;
    }
    [_tableView reloadData];
}

#pragma mark - textviewdelegate
- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    return YES;
}

- (void)textViewDidBeginEditing:(UITextView *)textView {}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if ([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        NSLog(@"%@",textView.text);
        [self exchangeHtmlFileContentWithString:textView.text];
        return NO;
    }
    return  YES;
}

- (BOOL)isFileExists:(NSString*)path {
    NSFileManager *manage = [NSFileManager defaultManager];
    
    BOOL ret = [manage fileExistsAtPath:path]
    && [manage isReadableFileAtPath:path];
    if (!ret) {
    }
    return ret;
}

- (void)exchangeHtmlFileContentWithString:(NSString*)newString
{
    NSString *fileName = @"test_xs.txt";
    if (_type == Replacement_ALL)
    {
        fileName = @"test_all.txt";
    }
    NSString *sPath = [[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] stringByAppendingPathComponent:fileName];
    BOOL bExist = [self isFileExists:sPath];
    NSLog(@"offline config path:%@, exist:%d", sPath, bExist);
    BOOL res = [newString writeToFile:sPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    NSString *string = @"文件写入成功";
    if (!res)
    {
        string = @"文件写入失败";
    }
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:string message:@"" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
    [alert show];
}

#pragma mark -
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    [self becomeFirstResponder];
}

@end
