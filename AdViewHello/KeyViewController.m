//
//  KeyViewController.m
//  AdViewHello
//
//  Created by AdView on 2017/6/22.
//
//

#import "KeyViewController.h"
@interface KeyViewController ()<UITableViewDelegate,UITableViewDataSource,UITextFieldDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *textArray;
@property (nonatomic, strong) NSString *content;
@end

@implementation KeyViewController

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL isOn = [[defaults objectForKey:USE_TEST_SERVER_KEY] boolValue];
    NSString *arrStr = @"keys";
    if (isOn) {
        arrStr = @"testKeys";
    }
    [defaults setObject:self.textArray forKey:arrStr];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[self.tableView indexPathForSelectedRow]];
    NSString *currentKey = cell.textLabel.text;
    if (currentKey && currentKey.length > 0) {
        [defaults setObject:currentKey forKey:@"currentKey"];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"KEY";
    
    UIImageView *view = [self.navigationController.navigationBar viewWithTag:10000];
    view.alpha = 0;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL isOn = [[defaults objectForKey:USE_TEST_SERVER_KEY] boolValue];
    NSString *arrStr = @"keys";
    if (isOn) {
        arrStr = @"testKeys";
    }
    NSMutableArray *keyArr = [defaults objectForKey:arrStr];
    self.textArray = keyArr;
    if (keyArr) {
        self.textArray = [[NSMutableArray alloc] initWithArray:keyArr];
    }else {
        self.textArray = [[NSMutableArray alloc] initWithCapacity:0];
    }
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
    return _textArray.count + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *reusableString = @"cell";
    UITableViewCellStyle style = UITableViewCellStyleDefault;
    if (indexPath.row == _textArray.count) {
        reusableString = @"cell1";
    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reusableString];
    if (nil == cell) {
        cell = [[UITableViewCell alloc] initWithStyle:style reuseIdentifier:reusableString];
        if (indexPath.row == _textArray.count) {
            UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(13, 2, ScreenWidth-26, 45)];
            textField.delegate = self;
            textField.returnKeyType = UIReturnKeyDone;
            [cell.contentView addSubview:textField];
            textField.placeholder = @"添加新key";
            textField.text = @"";
        }
    }
 
    if (indexPath.row != _textArray.count) {
        cell.textLabel.text = [_textArray objectAtIndex:indexPath.row];
    }else {
        for (UIView *view in cell.contentView.subviews) {
            if ([view isKindOfClass:[UITextField class]]) {
                UITextField *textField = (UITextField*)view;
                textField.text = @"";
            }
        }
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == _textArray.count) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
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

#pragma mark - textfileddelegate
- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    NSString *content = textField.text;
    content = [content stringByReplacingOccurrencesOfString:@" " withString:@""];
    textField.text = content;
    self.content = content;
    return YES;
}
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if ([string isEqualToString:@" "]) {
        return NO;
    } else if ([string isEqualToString:@"\n"]) {
        [textField resignFirstResponder];
        return YES;
    } else {
        return YES;
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    BOOL isExist = NO;
    NSString *string = @"该key已存在";
    if ([textField.text isEqualToString:@""]) {
        isExist = YES;
        string = @"key不能为空";
    }else {
        for (NSString *string in self.textArray) {
            if ([self.content isEqualToString:string]) {
                isExist = YES;
                break;
            }
        }
    }
    
    if (!isExist) {
        [self.textArray addObject:self.content];
        [self.tableView reloadData];
    }else {
        textField.text = @"";
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:string message:@"" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
        [alert show];
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
