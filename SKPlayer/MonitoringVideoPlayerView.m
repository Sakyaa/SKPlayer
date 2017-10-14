//
//  MonitoringVideoPlayerView.m
//  CityMonitoring
//
//  Created by Sakya on 2017/8/24.
//  Copyright © 2017年 Sakya. All rights reserved.
//

#import "MonitoringVideoPlayerView.h"
#import "SKPlayer.h"

// browser中显示图片动画时长
#define PlayerHideAnimationDuration 0.4f

@interface MonitoringVideoPlayerView ()<SKPlayerDelegate>

@property (nonatomic , strong) UIWindow *playerWindow;

@property (nonatomic, strong) SKPlayerView *playerView;


@property (nonatomic, strong) UIImageView *playerImageView;
@end

@implementation MonitoringVideoPlayerView {
    NSString *_title;
    NSString *_videoURL;
}

- (instancetype)initWithTitle:(NSString *)title
                    videoPath:(NSString *)videoPath {
    if (self = [super init]) {
        self.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.9];
        self.frame = [UIScreen mainScreen].bounds;
        _title = title;
        _videoURL = videoPath;
        [self initCustomView];
    }
    return self;
}
- (void)initCustomView {
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureDetected:)];
    [self addGestureRecognizer:tapGesture];
    
    //创建播放背景
    UIImageView *playerImageView = [[UIImageView alloc] init];
    playerImageView.backgroundColor = [UIColor blackColor];
    playerImageView.userInteractionEnabled = YES;
    playerImageView.frame = CGRectMake(0, 0, ScreenWidth, ScreenHeight / 16 * 9);
    playerImageView.center = self.center;
    [self addSubview:playerImageView];
    _playerImageView = playerImageView;
    //播放视频
    if (_videoURL) [self playVideo];
}
- (void)setPlayerTitle:(NSString *)title
             videoPath:(NSString *)videoPath {
    _title = title;
    _videoURL = videoPath;

}
- (void)playVideo {
    
    SKPlayerModel *playerModel = [[SKPlayerModel alloc] init];
    //创建虚拟URL为了加载动画
    playerModel.videoURL         = [NSURL URLWithString:_videoURL];
    playerModel.fatherView       = _playerImageView;
    playerModel.placeholderImage = [UIImage imageNamed:@"order_picture_placeholder_icon"];
    // 设置播放控制层和model
    self.playerView.delegate = self;
    [self.playerView playerModel:playerModel];
    [self.playerView autoPlayTheVideo];

}


- (SKPlayerView *)playerView {
    if (!_playerView) {
        _playerView = [[SKPlayerView alloc] init];
    }
    return _playerView;
}
- (UIWindow *)playerWindow {
    if (!_playerWindow) {
        
        //        _playerWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        //        _playerWindow.windowLevel = MAXFLOAT;
        //        UIViewController *tempVC = [[UIViewController alloc] init];
        //        tempVC.view.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.8];
        //        _playerWindow.rootViewController = tempVC;
        NSEnumerator *frontToBackWindows = [UIApplication.sharedApplication.windows reverseObjectEnumerator];
        for (UIWindow *window in frontToBackWindows) {
            BOOL windowOnMainScreen = window.screen == UIScreen.mainScreen;
            BOOL windowIsVisible = !window.hidden && window.alpha > 0;
            BOOL windowLevelSupported = (window.windowLevel >= UIWindowLevelNormal);
            BOOL windowSizeIsEqualToScreen = (window.frame.size.width == ScreenWidth && window.frame.size.height == ScreenHeight);
            if(windowOnMainScreen && windowIsVisible && windowLevelSupported && windowSizeIsEqualToScreen) {
                _playerWindow = window;
                return window;
            }
        }
        UIWindow * delegateWindow = [[[UIApplication sharedApplication] delegate] window];
        _playerWindow = delegateWindow;
        return delegateWindow;
        
    }
    return _playerWindow;
}
#pragma mark -  UITapGestureRecognizer
- (void)tapGestureDetected:(UITapGestureRecognizer *)sender {

    [self playerDismiss];
}
#pragma mark -- diss show methom
- (void)playerShow {
    
    self.alpha = 1.0;
    self.frame = self.playerWindow.bounds;
    [self.playerWindow addSubview:self];
    [self.playerWindow makeKeyAndVisible];
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
}
- (void)playerDismiss {
    //关闭播放器
    [_playerView shutdown];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    [UIView animateWithDuration:PlayerHideAnimationDuration animations:^{
        self.alpha = 0.0;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
        [self.playerWindow removeFromSuperview];
        self.playerWindow = nil;
    }];
}
- (void)sk_playerBackAction {
    [self playerDismiss];
}
- (void)sk_playDidEnd {
    [self playerDismiss];
}

- (void)dealloc {

}
@end
