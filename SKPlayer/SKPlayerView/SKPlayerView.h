//
//  SKPlayerView.h
//  SKPlayer
//
//  Created by Sakya on 2017/9/2.
//  Copyright © 2017年 Sakya. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIView+CustomControlView.h"
#import "SKPlayer.h"



@protocol SKPlayerDelegate <NSObject>
@optional
/** 返回按钮事件 */
- (void)sk_playerBackAction;
/** 下载视频 */
- (void)sk_playerDownload:(NSString *)url;
/**
 视频播放完毕
 */
- (void)sk_playDidEnd;
/** 控制层即将显示 */
- (void)sk_playerControlViewWillShow:(UIView *)controlView isFullscreen:(BOOL)fullscreen;
/** 控制层即将隐藏 */
- (void)sk_playerControlViewWillHidden:(UIView *)controlView isFullscreen:(BOOL)fullscreen;

@end
// playerLayer的填充模式（默认：等比例填充，直到一个维度到达区域边界）
typedef NS_ENUM(NSInteger, ZFPlayerLayerGravity) {
    ZFPlayerLayerGravityResize,           // 非均匀模式。两个维度完全填充至整个视图区域
    ZFPlayerLayerGravityResizeAspect,     // 等比例填充，直到一个维度到达区域边界
    ZFPlayerLayerGravityResizeAspectFill  // 等比例填充，直到填充满整个视图区域，其中一个维度的部分区域会被裁剪
};


// 播放器的几种状态

typedef NS_OPTIONS(NSInteger, ZFPlayerState) {
    ZFPlayerStateFailed = 0,     // 播放失败
    ZFPlayerStateBuffering,  // 缓冲中
    ZFPlayerStatePlaying,    // 播放中
    ZFPlayerStateStopped,    // 停止播放
    ZFPlayerStatePause       // 暂停播放
};

@interface SKPlayerView : UIView

/** 播发器的几种状态 */
@property (nonatomic, assign, readonly) ZFPlayerState state;

//设置播放
- (void)playerControlView:(UIView *)controlView playerModel:(SKPlayerModel *)playerModel;
/**
 * 使用自带的控制层时候可使用此API
 */
- (void)playerModel:(SKPlayerModel *)playerModel;

/** 设置代理 */
@property (nonatomic, weak) id<SKPlayerDelegate>      delegate;
/** 是否被用户暂停 */
@property (nonatomic, assign) BOOL                   isPauseByUser;

/**
 *  播放
 */
- (void)play;

/**
 * 暂停
 */
- (void)pause;
/**
 *  自动播放，默认不自动播放
 */
- (void)autoPlayTheVideo;

/**
 *  关闭player
 */
- (void)shutdown;
@end
