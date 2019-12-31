//
//  SoundView.m
//  KOpenAPIAdView
//
//  Created by AdView on 2018/5/3.
//

#import "AdViewSoundView.h"
#import <MediaPlayer/MediaPlayer.h>
#import <AudioToolbox/AudioToolbox.h>
#import "UIImage+AdViewBundle.h"
#import "AdViewExtTool.h"
#import <AVFoundation/AVFoundation.h>

@implementation AdViewSoundView
- (instancetype)init {
    if (self = [super init])
    {
        [self setInitImage];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        [self setInitImage];
    }
    return self;
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    self.layer.cornerRadius = self.frame.size.width / 2;
    self.layer.masksToBounds = YES;
}

- (void)setInitImage
{
    [self setImage:[UIImage imagesNamedFromCustomBundle:@"adview_video_unmute.png"] forState:UIControlStateNormal];
    [self setImage:[UIImage imagesNamedFromCustomBundle:@"adview_video_mute.png"] forState:UIControlStateSelected];
    
    [self setBackgroundColor:[AdViewExtTool hexStringToColor:@"#3FA0A0A0"]];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
