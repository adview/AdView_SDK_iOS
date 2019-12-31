//
//  AdInfoCell.m
//  AdViewHello
//
//  Created by AdView on 2017/6/29.
//
//

#import "AdInfoCell.h"

@interface AdInfoCell()

@property (nonatomic, assign) int infoNum; // 信息个数

@end

@implementation AdInfoCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.infoNum = 4;
        [self initSubVeiws];
    }
    return self;
}

- (void)initSubVeiws {
    for (int i = 0; i < _infoNum; i++) {
        UILabel *label = [[UILabel alloc] init];
        label.tag = i+10;
        label.textAlignment = NSTextAlignmentCenter;
        [self.contentView addSubview:label];
    }
}

- (void)layoutSubviews {
    CGSize size = self.contentView.frame.size;
    CGFloat space = 5;
    CGFloat width = 60;
    CGFloat lastWidth = (size.width - space*(_infoNum+1)) - width*(_infoNum-1);
    
    for (int i = 0; i < _infoNum; i++) {
        UILabel *label = [self.contentView viewWithTag:i+10];
        CGFloat w = width;
        if (i == _infoNum - 1) {
            w = lastWidth;
        }
        label.frame = CGRectMake(space + (width + space)*i, 0, w, size.height);
    }
}

- (void)showInfoWithDict:(NSDictionary *)infoDict {
    for (int i = 0; i < _infoNum; i++) {
        UILabel *label = [self.contentView viewWithTag:i+10];
        label.text = [infoDict objectForKey:[NSString stringWithFormat:@"%d",i+1]];
    }
}

#pragma mark -
- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
