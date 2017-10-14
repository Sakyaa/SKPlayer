//
//  SKPlayerView.m
//  SKPlayer
//
//  Created by Sakya on 2017/9/2.
//  Copyright © 2017年 Sakya. All rights reserved.
//

#import "SKPlayerView.h"
#import <IJKMediaFramework/IJKMediaFramework.h>
#import <AVFoundation/AVFoundation.h>


// 枚举值，包含水平移动方向和垂直移动方向
typedef NS_ENUM(NSInteger, PanDirection){
    PanDirectionHorizontalMoved, // 横向移动
    PanDirectionVerticalMoved    // 纵向移动
};


@interface SKPlayerView ()<SKPlayerCustomDelegate,UIGestureRecognizerDelegate>

@property (nonatomic , strong) UIWindow *playerWindow;
@property (nonatomic , strong) IJKFFMoviePlayerController *player;

@property (nonatomic, strong) UIView                  *playerview;
@property (nonatomic, strong) NSURL *url;
/** 是否为全屏 */
@property (nonatomic, assign) BOOL                   isFullScreen;
/** 是否锁定屏幕方向 */
@property (nonatomic, assign) BOOL                   isLocked;

@property (nonatomic, strong) UIView                 *controlView;

@property (nonatomic, assign) BOOL                   isAutoPlay;
/** 是否再次设置URL播放视频 */
@property (nonatomic, assign) BOOL                   repeatToPlay;
/** 播放完了*/
@property (nonatomic, assign) BOOL                   playDidEnd;
/** 进入后台*/
@property (nonatomic, assign) BOOL                   didEnterBackground;
@property (nonatomic, strong) SKPlayerModel          *playerModel;

@property (nonatomic, assign) NSInteger              seekTime;
/** 滑杆 */
@property (nonatomic, strong) UISlider               *volumeViewSlider;
/** 单击 */
@property (nonatomic, strong) UITapGestureRecognizer *singleTap;
/** 双击 */
@property (nonatomic, strong) UITapGestureRecognizer *doubleTap;
/** 亮度view */
@property (nonatomic, strong) SKPlayerStateView       *brightnessView;

/** 定义一个实例变量，保存枚举值 */
@property (nonatomic, assign) PanDirection           panDirection;
/** 是否在调节音量*/
@property (nonatomic, assign) BOOL                   isVolume;
/** 是否缩小视频在底部 */
@property (nonatomic, assign) BOOL                   isBottomVideo;
@end

@implementation SKPlayerView
- (instancetype)init {
    if (self = [super init]) {
        
        [self addNotifications];
        // 添加手势
        [self createGesture];
    }
    return self;
}
- (void)addNotifications {
    [self installMovieNotificationObservers];
}

#pragma mark  -- gesture  touch
/**
*  创建手势
*/
- (void)createGesture {
    // 单击
    self.singleTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(singleTapAction:)];
    self.singleTap.delegate                = self;
    self.singleTap.numberOfTouchesRequired = 1; //手指数
    self.singleTap.numberOfTapsRequired    = 1;
    [self addGestureRecognizer:self.singleTap];
    
    // 双击(播放/暂停)
    self.doubleTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(doubleTapAction:)];
    self.doubleTap.delegate                = self;
    self.doubleTap.numberOfTouchesRequired = 1; //手指数
    self.doubleTap.numberOfTapsRequired    = 2;
    [self addGestureRecognizer:self.doubleTap];
    
    // 加载完成后，再添加平移手势
    // 添加平移手势，用来控制音量、亮度、快进快退
    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(panDirection:)];
    panRecognizer.delegate = self;
    [panRecognizer setMaximumNumberOfTouches:1];
    [panRecognizer setDelaysTouchesBegan:YES];
    [panRecognizer setDelaysTouchesEnded:YES];
    [panRecognizer setCancelsTouchesInView:YES];
    [self addGestureRecognizer:panRecognizer];
    
    // 解决点击当前view时候响应其他控件事件
    [self.singleTap setDelaysTouchesBegan:YES];
    [self.doubleTap setDelaysTouchesBegan:YES];
    // 双击失败响应单击事件
    [self.singleTap requireGestureRecognizerToFail:self.doubleTap];
}
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if (self.isAutoPlay) {
        UITouch *touch = [touches anyObject];
        if(touch.tapCount == 1) {
            [self performSelector:@selector(singleTapAction:) withObject:@(NO) ];
        } else if (touch.tapCount == 2) {
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(singleTapAction:) object:nil];
            [self doubleTapAction:touch.gestureRecognizers.lastObject];
        }
    }
}



- (void)playerControlView:(UIView *)controlView playerModel:(SKPlayerModel *)playerModel {
    // 指定默认控制层
    SKPlayerCustomControlView *defaultControlView;
    if (!controlView) {
        defaultControlView = [[SKPlayerCustomControlView alloc] init];
    } else {
        defaultControlView = (SKPlayerCustomControlView *)controlView;
    }
    self.controlView = defaultControlView;
    self.playerModel = playerModel;
}
- (void)playerModel:(SKPlayerModel *)playerModel {
    // 指定默认控制层
    [self playerControlView:nil playerModel:playerModel];
}
#pragma mark - Action

/**
 *   轻拍方法
 *
 *  @param gesture UITapGestureRecognizer
 */
- (void)singleTapAction:(UIGestureRecognizer *)gesture {
    if ([gesture isKindOfClass:[NSNumber class]] && ![(id)gesture boolValue]) {
        [self _fullScreenAction];
        return;
    }
    if (gesture.state == UIGestureRecognizerStateRecognized) {
        if (self.isBottomVideo &&!self.isFullScreen) { [self _fullScreenAction]; }
        else {
            if (self.playDidEnd) { return; }
            else {
                [self.controlView sk_playerShowOrHideControlView];
            }
        }
    }
}

/**
 *  双击播放/暂停
 *
 *  @param gesture UITapGestureRecognizer
 */
- (void)doubleTapAction:(UIGestureRecognizer *)gesture {
    if (self.playDidEnd) { return;  }
    // 显示控制层
    [self.controlView sk_playerShowControlView];
    if (self.isPauseByUser) { [self play]; }
    else { [self pause]; }
    if (!self.isAutoPlay) {
        self.isAutoPlay = YES;
        [self configSKPlayer];
    }
}
#pragma mark - UIPanGestureRecognizer手势方法

/**
 *  pan手势事件
 *
 *  @param pan UIPanGestureRecognizer
 */
- (void)panDirection:(UIPanGestureRecognizer *)pan {
    //根据在view上Pan的位置，确定是调音量还是亮度
    CGPoint locationPoint = [pan locationInView:self];
    
    // 我们要响应水平移动和垂直移动
    // 根据上次和本次移动的位置，算出一个速率的point
    CGPoint veloctyPoint = [pan velocityInView:self];
    
    // 判断是垂直移动还是水平移动
    switch (pan.state) {
        case UIGestureRecognizerStateBegan:{ // 开始移动
       
            // 使用绝对值来判断移动的方向
            CGFloat x = fabs(veloctyPoint.x);
            CGFloat y = fabs(veloctyPoint.y);
                 /**
            if (x > y) { // 水平移动
                // 取消隐藏
                self.panDirection = PanDirectionHorizontalMoved;
                // 给sumTime初值
                CMTime time       = self.player.currentTime;
                self.sumTime      = time.value/time.timescale;
            }
            else 
             */
             if (x < y){ // 垂直移动
                self.panDirection = PanDirectionVerticalMoved;
                // 开始滑动的时候,状态改为正在控制音量
                if (locationPoint.x > self.bounds.size.width / 2) {
                    self.isVolume = YES;
                }else { // 状态改为显示亮度调节
                    self.isVolume = NO;
                }
            }
            break;
        }
        case UIGestureRecognizerStateChanged:{ // 正在移动
            switch (self.panDirection) {
                case PanDirectionHorizontalMoved:{
                    [self horizontalMoved:veloctyPoint.x]; // 水平移动的方法只要x方向的值
                    break;
                }
                case PanDirectionVerticalMoved:{
                    [self verticalMoved:veloctyPoint.y]; // 垂直移动方法只要y方向的值
                    break;
                }
                default:
                    break;
            }
            break;
        }
        case UIGestureRecognizerStateEnded:{ // 移动停止
            // 移动结束也需要判断垂直或者平移
            // 比如水平移动结束时，要快进到指定位置，如果这里没有判断，当我们调节音量完之后，会出现屏幕跳动的bug
            switch (self.panDirection) {
                case PanDirectionHorizontalMoved:{
                    /**
                    self.isPauseByUser = NO;
                    [self seekToTime:self.sumTime completionHandler:nil];
                    // 把sumTime滞空，不然会越加越多
                    self.sumTime = 0;
                     */
                    break;
                }
                case PanDirectionVerticalMoved:{
                    // 垂直移动结束后，把状态改为不再控制音量
                    self.isVolume = NO;
                    break;
                }
                default:
                    break;
            }
            break;
        }
        default:
            break;
    }
}

/**
 *  pan垂直移动的方法
 *
 *  @param value void
 */
- (void)verticalMoved:(CGFloat)value {
    self.isVolume ? (self.volumeViewSlider.value -= value / 10000) : ([UIScreen mainScreen].brightness -= value / 10000);
}

/**
 *  pan水平移动的方法
 *
 *  @param value void
 */
- (void)horizontalMoved:(CGFloat)value {
    /**
    // 每次滑动需要叠加时间
    self.sumTime += value / 200;
    
    // 需要限定sumTime的范围
    CMTime totalTime           = self.playerItem.duration;
    CGFloat totalMovieDuration = (CGFloat)totalTime.value/totalTime.timescale;
    if (self.sumTime > totalMovieDuration) { self.sumTime = totalMovieDuration;}
    if (self.sumTime < 0) { self.sumTime = 0; }
    
    BOOL style = false;
    if (value > 0) { style = YES; }
    if (value < 0) { style = NO; }
    if (value == 0) { return; }
    
    self.isDragged = YES;
    [self.controlView zf_playerDraggedTime:self.sumTime totalTime:totalMovieDuration isForward:style hasPreview:NO];
     */
}
/**
- (void)shrikPanAction:(UIPanGestureRecognizer *)gesture {
    CGPoint point = [gesture locationInView:[UIApplication sharedApplication].keyWindow];
    SKPlayerView *view = (SKPlayerView *)gesture.view;
    const CGFloat width = view.frame.size.width;
    const CGFloat height = view.frame.size.height;
    const CGFloat distance = 10;  // 离四周的最小边距
    
    if (gesture.state == UIGestureRecognizerStateEnded) {
        // x轴的的移动
        if (point.x < width/2) {
            point.x = width/2 + distance;
        } else if (point.x > ScreenWidth - width/2) {
            point.x = ScreenWidth - width/2 - distance;
        }
        // y轴的移动
        if (point.y < height/2) {
            point.y = height/2 + distance;
        } else if (point.y > ScreenHeight - height/2) {
            point.y = ScreenHeight - height/2 - distance;
        }
        
        [UIView animateWithDuration:0.5 animations:^{
            view.center = point;
            self.shrinkRightBottomPoint = CGPointMake(ScreenWidth - view.frame.origin.x - width, ScreenHeight - view.frame.origin.y - height);
        }];
        
    } else {
        view.center = point;
        self.shrinkRightBottomPoint = CGPointMake(ScreenWidth - view.frame.origin.x- view.frame.size.width, ScreenHeight - view.frame.origin.y-view.frame.size.height);
    }
}
*/
/** 全屏 */
- (void)_fullScreenAction {
    if (SKPlayerShared.isLockScreen) {
        [self unLockTheScreen];
        return;
    }
    if (self.isFullScreen) {
        [self interfaceOrientation:UIInterfaceOrientationPortrait];
        self.isFullScreen = NO;
        return;
    } else {
        UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
        if (orientation == UIDeviceOrientationLandscapeRight) {
            [self interfaceOrientation:UIInterfaceOrientationLandscapeLeft];
        } else {
            [self interfaceOrientation:UIInterfaceOrientationLandscapeRight];
        }
        self.isFullScreen = YES;
    }
}
#pragma mark - layoutSubviews

- (void)layoutSubviews {
    [super layoutSubviews];
    self.playerview.frame = self.bounds;
}

#pragma mark -- getter
- (SKPlayerStateView *)brightnessView {
    if (!_brightnessView) {
        _brightnessView = [SKPlayerStateView shareInstance];
    }
    return _brightnessView;
}
#pragma mark -- setter
- (void)setControlView:(UIView *)controlView {
    if (_controlView) { return; }
    _controlView = controlView;
    controlView.delegate = self;
    //设置控制页面
    [self addSubview:controlView];
    [controlView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(UIEdgeInsetsZero);
    }];
}

/**
 *  设置播放的状态
 *
 *  @param state ZFPlayerState
 */
- (void)setState:(ZFPlayerState)state {
    _state = state;
    // 控制菊花显示、隐藏
    [self.controlView sk_playerActivity:state == ZFPlayerStateBuffering];
    if (state == ZFPlayerStatePlaying || state == ZFPlayerStateBuffering) {
        // 隐藏占位图
        [self.controlView sk_playerItemPlaying];
    } else if (state == ZFPlayerStateFailed) {
//        NSError *error = [self.player error];
        NSError *error;
        [self.controlView sk_playerItemStatusFailed:error];
    }
}
- (void)setPlayerModel:(SKPlayerModel *)playerModel {
    _playerModel = playerModel;
    //绑定数据
    if (playerModel.historyTime) { self.seekTime = playerModel.historyTime; }
//    绑定控制器数据
    [self.controlView sk_playerModel:playerModel];
//将播放器添加到父类控制器
    NSCAssert(playerModel.fatherView, @"请指定playerView的faterView");
    [self addPlayerToFatherView:playerModel.fatherView];
    self.url = playerModel.videoURL;
}
- (void)setUrl:(NSURL *)url {
    _url = url;
    //
    IJKFFOptions *options = [IJKFFOptions optionsByDefault]; //使用默认配置
//    创建播放器
    _player = [[IJKFFMoviePlayerController alloc] initWithContentURL:_url withOptions:options];
//    添加播放器视图
    [self setUpPlayerView];
//    设置播放器状态
    self.state = ZFPlayerStateBuffering;
    // 每次加载视频URL都设置重播为NO
    self.repeatToPlay = NO;
    self.playDidEnd   = NO;
    self.isPauseByUser = YES;
}


#pragma Install Notifiacation
//注册通知
- (void)installMovieNotificationObservers {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(loadStateDidChange:)
                                                 name:IJKMPMoviePlayerLoadStateDidChangeNotification
                                               object:_player];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayBackFinish:)
                                                 name:IJKMPMoviePlayerPlaybackDidFinishNotification
                                               object:_player];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(mediaIsPreparedToPlayDidChange:)
                                                 name:IJKMPMediaPlaybackIsPreparedToPlayDidChangeNotification
                                               object:_player];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayBackStateDidChange:)
                                                 name:IJKMPMoviePlayerPlaybackStateDidChangeNotification
                                               object:_player];
    
    //系统
    // app退到后台
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground) name:UIApplicationWillResignActiveNotification object:nil];
    // app进入前台
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterPlayground) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    // 监听耳机插入和拔掉通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioRouteChangeListenerCallback:) name:AVAudioSessionRouteChangeNotification object:nil];
    // 监测设备方向
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onDeviceOrientationChange)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onStatusBarOrientationChange)
                                                 name:UIApplicationDidChangeStatusBarOrientationNotification
                                               object:nil];
    //
//    NSTimer *    splashTimer = nil;
//    
//    splashTimer = [NSTimer scheduledTimerWithTimeInterval:0.1  target:self selector:@selector(rote) userInfo:nil repeats:YES];
}

- (void)removeMovieNotificationObservers {
    
    // 移除通知
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:IJKMPMoviePlayerLoadStateDidChangeNotification
                                                  object:_player];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:IJKMPMoviePlayerPlaybackDidFinishNotification
                                                  object:_player];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:IJKMPMediaPlaybackIsPreparedToPlayDidChangeNotification
                                                  object:_player];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:IJKMPMoviePlayerPlaybackStateDidChangeNotification
                                                  object:_player];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVAudioSessionRouteChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];

    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
}

#pragma Selector func
/**
 *  屏幕方向发生变化会调用这里
 */
- (void)onDeviceOrientationChange {
    if (!self.player) { return; }
    if (SKPlayerShared.isLockScreen) { return; }
    if (self.didEnterBackground) { return; };
    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
    UIInterfaceOrientation interfaceOrientation = (UIInterfaceOrientation)orientation;
    if (orientation == UIDeviceOrientationFaceUp || orientation == UIDeviceOrientationFaceDown || orientation == UIDeviceOrientationUnknown ) { return; }
    switch (interfaceOrientation) {
        case UIInterfaceOrientationPortraitUpsideDown:{
        }
            break;
        case UIInterfaceOrientationPortrait:{
            if (self.isFullScreen) {
                [self toOrientation:UIInterfaceOrientationPortrait];
                
            }
        }
            break;
        case UIInterfaceOrientationLandscapeLeft:{
            if (self.isFullScreen == NO) {
                [self toOrientation:UIInterfaceOrientationLandscapeLeft];
                self.isFullScreen = YES;
            } else {
                [self toOrientation:UIInterfaceOrientationLandscapeLeft];
            }
            
        }
            break;
        case UIInterfaceOrientationLandscapeRight:{
            if (self.isFullScreen == NO) {
                [self toOrientation:UIInterfaceOrientationLandscapeRight];
                self.isFullScreen = YES;
            } else {
                [self toOrientation:UIInterfaceOrientationLandscapeRight];
            }
        }
            break;
        default:
            break;
    }

}
- (void)onStatusBarOrientationChange {
    if (!self.didEnterBackground) {
        // 获取到当前状态条的方向
        UIInterfaceOrientation currentOrientation = [UIApplication sharedApplication].statusBarOrientation;
        if (currentOrientation == UIInterfaceOrientationPortrait) {
            [self setOrientationPortraitConstraint];
      
            [self.brightnessView removeFromSuperview];
            [[UIApplication sharedApplication].keyWindow addSubview:self.brightnessView];
            [self.brightnessView mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.width.height.mas_equalTo(155);
                make.leading.mas_equalTo((ScreenWidth-155)/2);
                make.top.mas_equalTo((ScreenHeight-155)/2);
            }];
        } else {
            if (currentOrientation == UIInterfaceOrientationLandscapeRight) {
                [self toOrientation:UIInterfaceOrientationLandscapeRight];
            } else if (currentOrientation == UIDeviceOrientationLandscapeLeft){
                [self toOrientation:UIInterfaceOrientationLandscapeLeft];
            }
            [self.brightnessView removeFromSuperview];
            [self addSubview:self.brightnessView];
            [self.brightnessView mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.center.mas_equalTo(self);
                make.width.height.mas_equalTo(155);
            }];
            
        }
    }

}
#pragma mark 屏幕转屏相关

- (void)toOrientation:(UIInterfaceOrientation)orientation {
    // 获取到当前状态条的方向
    UIInterfaceOrientation currentOrientation = [UIApplication sharedApplication].statusBarOrientation;
    // 判断如果当前方向和要旋转的方向一致,那么不做任何操作
    if (currentOrientation == orientation) { return; }

    // 根据要旋转的方向,使用Masonry重新修改限制
    if (orientation != UIInterfaceOrientationPortrait) {//
        // 这个地方加判断是为了从全屏的一侧,直接到全屏的另一侧不用修改限制,否则会出错;
        if (currentOrientation == UIInterfaceOrientationPortrait) {
            [self removeFromSuperview];
            SKPlayerStateView *brightnessView = [SKPlayerStateView shareInstance];
            [[UIApplication sharedApplication].keyWindow addSubview:brightnessView];
            [[UIApplication sharedApplication].keyWindow insertSubview:self belowSubview:brightnessView];
            
            [self mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.width.equalTo(@(ScreenHeight));
                make.height.equalTo(@(ScreenWidth));
                make.center.equalTo([UIApplication sharedApplication].keyWindow);
            }];
        }
    }
    
    // iOS6.0之后,设置状态条的方法能使用的前提是shouldAutorotate为NO,也就是说这个视图控制器内,旋转要关掉;
    // 也就是说在实现这个方法的时候-(BOOL)shouldAutorotate返回值要为NO
    [[UIApplication sharedApplication] setStatusBarOrientation:orientation animated:NO];
    // 获取旋转状态条需要的时间:
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.3];
    // 更改了状态条的方向,但是设备方向UIInterfaceOrientation还是正方向的,这就要设置给你播放视频的视图的方向设置旋转
    // 给你的播放视频的view视图设置旋转
    self.transform = CGAffineTransformIdentity;
    self.transform = [self getTransformRotationAngle];
    // 开始旋转
    [UIView commitAnimations];
}
/**
 * 获取变换的旋转角度
 *
 * @return 角度
 */
- (CGAffineTransform)getTransformRotationAngle {
    // 状态条的方向已经设置过,所以这个就是你想要旋转的方向
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    // 根据要进行旋转的方向来计算旋转的角度
    if (orientation == UIInterfaceOrientationPortrait) {
        return CGAffineTransformIdentity;
    } else if (orientation == UIInterfaceOrientationLandscapeLeft){
        return CGAffineTransformMakeRotation(-M_PI_2);
    } else if(orientation == UIInterfaceOrientationLandscapeRight){
        return CGAffineTransformMakeRotation(M_PI_2);
    }
    return CGAffineTransformIdentity;
}
/**
 *  屏幕转屏
 *
 *  @param orientation 屏幕方向
 */
- (void)interfaceOrientation:(UIInterfaceOrientation)orientation {
    if (orientation == UIInterfaceOrientationLandscapeRight || orientation == UIInterfaceOrientationLandscapeLeft) {
        // 设置横屏
        [self setOrientationLandscapeConstraint:orientation];
    } else if (orientation == UIInterfaceOrientationPortrait) {
        // 设置竖屏
        [self setOrientationPortraitConstraint];
    }
}
/**
 *  设置横屏的约束
 */
- (void)setOrientationLandscapeConstraint:(UIInterfaceOrientation)orientation {
    [self toOrientation:orientation];
    self.isFullScreen = YES;
}
/**
 *  设置竖屏的约束
 */
- (void)setOrientationPortraitConstraint {
  
    [self addPlayerToFatherView:self.playerModel.fatherView];
    [self toOrientation:UIInterfaceOrientationPortrait];
    self.isFullScreen = NO;
}
/**
 *  解锁屏幕方向锁定
 */
- (void)unLockTheScreen {
    // 调用AppDelegate单例记录播放状态是否锁屏
    SKPlayerShared.isLockScreen = NO;
    [self.controlView sk_playerLockBtnState:NO];
    self.isLocked = NO;
    [self interfaceOrientation:UIInterfaceOrientationPortrait];
}


#pragma mark --  notifications

- (void)loadStateDidChange:(NSNotification*)notification {
    IJKMPMovieLoadState loadState = _player.loadState;
    
    if ((loadState & IJKMPMovieLoadStatePlaythroughOK) != 0) {
        NSLog(@"LoadStateDidChange: IJKMovieLoadStatePlayThroughOK: %d\n",(int)loadState);

    }else if ((loadState & IJKMPMovieLoadStateStalled) != 0) {
        NSLog(@"loadStateDidChange: IJKMPMovieLoadStateStalled: %d\n", (int)loadState);
    } else {
        NSLog(@"loadStateDidChange: ???: %d\n", (int)loadState);
    }
}

- (void)moviePlayBackFinish:(NSNotification*)notification {
    int reason =[[[notification userInfo] valueForKey:IJKMPMoviePlayerPlaybackDidFinishReasonUserInfoKey] intValue];
    switch (reason) {
        case IJKMPMovieFinishReasonPlaybackEnded:
            NSLog(@"playbackStateDidChange: IJKMPMovieFinishReasonPlaybackEnded: %d\n", reason);
            [self moviePlayDidEnd];
            break;
            
        case IJKMPMovieFinishReasonUserExited:
            NSLog(@"playbackStateDidChange: IJKMPMovieFinishReasonUserExited: %d\n", reason);
            break;
            
        case IJKMPMovieFinishReasonPlaybackError:
            NSLog(@"playbackStateDidChange: IJKMPMovieFinishReasonPlaybackError: %d\n", reason);
            self.state = ZFPlayerStateFailed;
            break;
            
        default:
            NSLog(@"playbackPlayBackDidFinish: ???: %d\n", reason);
            break;
    }
}

- (void)mediaIsPreparedToPlayDidChange:(NSNotification*)notification {
    
    NSLog(@"mediaIsPrepareToPlayDidChange\n");

}

- (void)moviePlayBackStateDidChange:(NSNotification*)notification {
    
    
    switch (_player.playbackState) {
            
        case IJKMPMoviePlaybackStateStopped:
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: stoped", (int)_player.playbackState);
            self.state = ZFPlayerStateStopped;

            break;
            
        case IJKMPMoviePlaybackStatePlaying:
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: playing", (int)_player.playbackState);
            self.state = ZFPlayerStatePlaying;
            [self refreshMediaControl];

            break;
            
        case IJKMPMoviePlaybackStatePaused:
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: paused", (int)_player.playbackState);
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(refreshMediaControl) object:nil];
            self.state = ZFPlayerStatePause;

            
            break;
            
        case IJKMPMoviePlaybackStateInterrupted:
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: interrupted", (int)_player.playbackState);
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(refreshMediaControl) object:nil];

            break;
            
        case IJKMPMoviePlaybackStateSeekingForward:
        case IJKMPMoviePlaybackStateSeekingBackward: {
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: seeking", (int)_player.playbackState);
            break;
        }
            
        default: {
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: unknown", (int)_player.playbackState);
            break;
        }
    }
}
/**
 *  应用退到后台
 */
- (void)appDidEnterBackground {
    self.didEnterBackground     = YES;
    // 退到后台锁定屏幕方向
    SKPlayerShared.isLockScreen = YES;
    [_player pause];
    self.state                  = ZFPlayerStatePause;
}

/**
 *  应用进入前台
 */
- (void)appDidEnterPlayground {
    self.didEnterBackground     = NO;
    // 根据是否锁定屏幕方向 来恢复单例里锁定屏幕的方向
    SKPlayerShared.isLockScreen = self.isLocked;
    if (!self.isPauseByUser) {
        self.state         = ZFPlayerStatePlaying;
        self.isPauseByUser = NO;
        [self play];
    }
}
/**
 *  耳机插入、拔出事件
 */
- (void)audioRouteChangeListenerCallback:(NSNotification*)notification {
    NSDictionary *interuptionDict = notification.userInfo;
    
    NSInteger routeChangeReason = [[interuptionDict valueForKey:AVAudioSessionRouteChangeReasonKey] integerValue];
    
    switch (routeChangeReason) {
            
        case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
            // 耳机插入
            break;
            
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
        {
            // 耳机拔掉
            // 拔掉耳机继续播放
            [self play];
        }
            break;
            
        case AVAudioSessionRouteChangeReasonCategoryChange:
            // called at start - also when other audio wants to play
            NSLog(@"AVAudioSessionRouteChangeReasonCategoryChange");
            break;
    }
}
#pragma mark - SKPlayerControlViewDelegate
- (void)sk_controlView:(UIView *)controlView playAction:(UIButton *)sender {
    self.isPauseByUser = !self.isPauseByUser;
    if (self.isPauseByUser) {
        [self pause];
        if (self.state == ZFPlayerStatePlaying) {
            self.state = ZFPlayerStatePause;}
    } else {
        [self play];
        if (self.state == ZFPlayerStatePause) { self.state = ZFPlayerStatePlaying; }
    }
    if (!self.isAutoPlay) {
        self.isAutoPlay = YES;
        [self configSKPlayer];
    }
}

- (void)sk_controlView:(UIView *)controlView backAction:(UIButton *)sender {
    if (SKPlayerShared.isLockScreen) {
        [self unLockTheScreen];
    } else {
        if (!self.isFullScreen) {
            // player加到控制器上，只有一个player时候
            [self pause];
            if ([self.delegate respondsToSelector:@selector(sk_playerBackAction)]) { [self.delegate sk_playerBackAction]; }
        } else {
            [self interfaceOrientation:UIInterfaceOrientationPortrait];
        }
    }
}

- (void)sk_controlView:(UIView *)controlView closeAction:(UIButton *)sender {
    [self shutdown];
    [self removeFromSuperview];
}

- (void)sk_controlView:(UIView *)controlView fullScreenAction:(UIButton *)sender {
    [self _fullScreenAction];
}

- (void)sk_controlView:(UIView *)controlView lockScreenAction:(UIButton *)sender {
    self.isLocked               = sender.selected;
    // 调用AppDelegate单例记录播放状态是否锁屏
    SKPlayerShared.isLockScreen = sender.selected;
}

- (void)sk_controlView:(UIView *)controlView cneterPlayAction:(UIButton *)sender {
    [self configSKPlayer];
}

- (void)sk_controlView:(UIView *)controlView repeatPlayAction:(UIButton *)sender {
    // 没有播放完
    self.playDidEnd   = NO;
    // 重播改为NO
    self.repeatToPlay = NO;

    if ([self.url.scheme isEqualToString:@"file"]) {
        self.state = ZFPlayerStatePlaying;
        
    } else {
        self.state = ZFPlayerStateBuffering;
        [self configSKPlayer];
        [self  play];
    }

}

/** 加载失败按钮事件 */
- (void)sk_controlView:(UIView *)controlView failAction:(UIButton *)sender {
    [self configSKPlayer];
}
/**
- (void)sk_controlView:(UIView *)controlView resolutionAction:(UIButton *)sender {
    // 记录切换分辨率的时刻
    NSInteger currentTime = (NSInteger)CMTimeGetSeconds([self.player currentTime]);
    NSString *videoStr = self.videoURLArray[sender.tag - 200];
    NSURL *videoURL = [NSURL URLWithString:videoStr];
    if ([videoURL isEqual:self.videoURL]) { return; }
    self.isChangeResolution = YES;
    // reset player
    [self resetToPlayNewURL];
    self.videoURL = videoURL;
    // 从xx秒播放
    self.seekTime = currentTime;
    // 切换完分辨率自动播放
    [self autoPlayTheVideo];
}
*/

- (void)sk_controlView:(UIView *)controlView downloadVideoAction:(UIButton *)sender {
    NSString *urlStr = self.url.absoluteString;
    if ([self.delegate respondsToSelector:@selector(sk_playerDownload:)]) {
        [self.delegate sk_playerDownload:urlStr];
    }
}

- (void)sk_controlView:(UIView *)controlView progressSliderTap:(CGFloat)value {
    
    /**
    // 视频总时间长度
    CGFloat total = self.player.monitor.duration/1000;
    //计算出拖动的当前秒数
    NSInteger dragedSeconds = floorf(total * value);
    
    [self.controlView sk_playerPlayBtnState:YES];
    [self seekToTime:dragedSeconds completionHandler:^(BOOL finished) {}];
    */
    
}

- (void)sk_controlView:(UIView *)controlView progressSliderValueChanged:(UISlider *)slider {
    /**
    // 拖动改变视频播放进度
    if (self.player.currentItem.status == AVPlayerItemStatusReadyToPlay) {
        self.isDragged = YES;
        BOOL style = false;
        CGFloat value   = slider.value - self.sliderLastValue;
        if (value > 0) { style = YES; }
        if (value < 0) { style = NO; }
        if (value == 0) { return; }
        
        self.sliderLastValue  = slider.value;
        
        CGFloat totalTime     = (CGFloat)_playerItem.duration.value / _playerItem.duration.timescale;
        
        //计算出拖动的当前秒数
        CGFloat dragedSeconds = floorf(totalTime * slider.value);
        
        //转换成CMTime才能给player来控制播放进度
        CMTime dragedCMTime   = CMTimeMake(dragedSeconds, 1);
        
        [controlView sk_playerDraggedTime:dragedSeconds totalTime:totalTime isForward:style hasPreview:self.isFullScreen ? self.hasPreviewView : NO];
        
        if (totalTime > 0) { // 当总时长 > 0时候才能拖动slider
            if (self.isFullScreen && self.hasPreviewView) {
                
                [self.imageGenerator cancelAllCGImageGeneration];
                self.imageGenerator.appliesPreferredTrackTransform = YES;
                self.imageGenerator.maximumSize = CGSizeMake(100, 56);
                AVAssetImageGeneratorCompletionHandler handler = ^(CMTime requestedTime, CGImageRef im, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error){
                    NSLog(@"%zd",result);
                    if (result != AVAssetImageGeneratorSucceeded) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [controlView sk_playerDraggedTime:dragedSeconds sliderImage:self.thumbImg ? : ZFPlayerImage(@"ZFPlayer_loading_bgView")];
                        });
                    } else {
                        self.thumbImg = [UIImage imageWithCGImage:im];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [controlView sk_playerDraggedTime:dragedSeconds sliderImage:self.thumbImg ? : ZFPlayerImage(@"ZFPlayer_loading_bgView")];
                        });
                    }
                };
                [self.imageGenerator generateCGImagesAsynchronouslyForTimes:[NSArray arrayWithObject:[NSValue valueWithCMTime:dragedCMTime]] completionHandler:handler];
            }
        } else {
            // 此时设置slider值为0
            slider.value = 0;
        }
        
    }else { // player状态加载失败
        // 此时设置slider值为0
        slider.value = 0;
    }
     */
    
}

- (void)sk_controlView:(UIView *)controlView progressSliderTouchEnded:(UISlider *)slider {
    if (self.player.playbackRate == IJKMPMoviePlaybackStatePlaying) {
        self.isPauseByUser = NO;
        // 视频总时间长度
//        CGFloat total           = (CGFloat)_playerItem.duration.value / _playerItem.duration.timescale;
        //计算出拖动的当前秒数
//        NSInteger dragedSeconds = floorf(total * slider.value);
//        [self seekToTime:dragedSeconds completionHandler:nil];
    }
}

- (void)sk_controlViewWillShow:(UIView *)controlView isFullscreen:(BOOL)fullscreen {
    if ([self.delegate respondsToSelector:@selector(sk_playerControlViewWillShow:isFullscreen:)]) {
        [self.delegate sk_playerControlViewWillShow:controlView isFullscreen:fullscreen];
    }
}

- (void)sk_controlViewWillHidden:(UIView *)controlView isFullscreen:(BOOL)fullscreen {
    if ([self.delegate respondsToSelector:@selector(sk_playerControlViewWillHidden:isFullscreen:)]) {
        [self.delegate sk_playerControlViewWillHidden:controlView isFullscreen:fullscreen];
    }
}

#pragma mark -- Private Method
/**
 *  设置Player相关参数
 */
- (void)configSKPlayer {

    // 获取系统音量
    [self configureVolume];
    
    [self.player prepareToPlay];
    self.player.scalingMode = IJKMPMovieScalingModeAspectFit; //缩放模式
    self.player.shouldAutoplay = YES; //开启自动播放
    self.isAutoPlay = YES;// 自动播放

    // 开始播放
    [self play];
}
/**
 *  获取系统音量
 */
- (void)configureVolume {
    MPVolumeView *volumeView = [[MPVolumeView alloc] init];
    _volumeViewSlider = nil;
    for (UIView *view in [volumeView subviews]){
        if ([view.class.description isEqualToString:@"MPVolumeSlider"]){
            _volumeViewSlider = (UISlider *)view;
            break;
        }
    }
    
    // 使用这个category的应用不会随着手机静音键打开而静音，可在手机静音下播放声音
    NSError *setCategoryError = nil;
    BOOL success = [[AVAudioSession sharedInstance]
                    setCategory: AVAudioSessionCategoryPlayback
                    error: &setCategoryError];
    
    if (!success) { /* handle the error in setCategoryError */ }
    
}
/**
 *  player添加到fatherView上
 */
- (void)addPlayerToFatherView:(UIView *)view {
    // 这里应该添加判断，因为view有可能为空，当view为空时[view addSubview:self]会crash
    if (view) {
        [self removeFromSuperview];
        // 自动调整自己的宽度和高度
        [view addSubview:self];
        [self mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.edges.mas_offset(UIEdgeInsetsZero);
        }];

    }
}

/**
 创建时间进度条
 */
- (void)setUpTimer {
    
    CGFloat currentPlayTime = self.player.currentPlaybackTime;
    // 视频总时间长度
    CGFloat total = self.player.monitor.duration/1000;
    //计算出拖动的当前秒数
    NSInteger dragedSeconds = [[NSString stringWithFormat:@"%.f",total] integerValue];
    //当前的视频
    NSInteger currentSeconds = [[NSString stringWithFormat:@"%.f",currentPlayTime] integerValue];
    //缓冲的视频
    NSLog(@" %f**%ld",self.player.playableDuration,(long)self.player.bufferingProgress);
    CGFloat value = currentPlayTime/total;
    [self.controlView sk_playerCurrentTime:currentSeconds totalTime:dragedSeconds sliderValue:value];
    //缓冲进度暂时没有实现
//    [self.controlView sk_playerSetProgress:self.player.bufferingProgress];

}
/**
 *  播放完了
 *
 */
- (void)moviePlayDidEnd {
    
    //如果是全屏则需要先竖屏
    if (self.isFullScreen) {
        [self setOrientationPortraitConstraint];
    }
//    播放完毕暂时直接关闭
    if (self.delegate && [self.delegate respondsToSelector:@selector(sk_playDidEnd)]) {
        [self.delegate sk_playDidEnd];
    }
    /**
    self.state = ZFPlayerStateStopped;
    if (self.isBottomVideo && !self.isFullScreen) { // 播放完了，如果是在小屏模式 && 在bottom位置，直接关闭播放器
        self.repeatToPlay = NO;
        self.playDidEnd   = NO;
    } else {
        self.playDidEnd = YES;
        [self.controlView sk_playerPlayEnd];
    }
    */
}

/**
 初始化播放的背景View
 */
- (void)setUpPlayerView {
    [self.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[[_player view] class]]) {
            [[_player view] removeFromSuperview];
            *stop = YES;
        }
    }];
    UIView *playerview = [_player view];
    //    [self addSubview:playerview];
    [self insertSubview:playerview atIndex:0];
    _playerview = playerview;
}

#pragma mark -- Publick

/**
 自动播放
 */
- (void)autoPlayTheVideo {
    [self configSKPlayer];
}
//关闭播放器
- (void)shutdown {
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(refreshMediaControl) object:nil];
    [self.player shutdown];
    [self.brightnessView removeFromSuperview];
}
/**
 *  播放
 */
- (void)play {
    
    [self.controlView sk_playerPlayBtnState:YES];
    if (self.state == ZFPlayerStatePause) { self.state = ZFPlayerStatePlaying; }
    self.isPauseByUser = NO;
    [self.player play];
}

/**
 * 暂停
 */
- (void)pause {
    
    [self.controlView sk_playerPlayBtnState:NO];
    if (self.state == ZFPlayerStatePlaying) { self.state = ZFPlayerStatePause;}
    self.isPauseByUser = YES;
    [self.player pause];
}

#pragma mark -- perform-methom
- (void)refreshMediaControl {
    
    if (self.state == ZFPlayerStatePlaying) {
        [self setUpTimer];

        [self performSelector:@selector(refreshMediaControl) withObject:nil afterDelay:0.5];
    } else {
        [self performSelector:@selector(refreshMediaControl) withObject:nil afterDelay:0.5];
    }
}


- (void)dealloc {

    SKPlayerShared.isLockScreen = NO;
    [self.controlView sk_playerCancelAutoFadeOutControlView];
    [self removeMovieNotificationObservers];
}

@end
