//
//  UIView+CustomControlView.m
//  SKPlayer
//
//  Created by Sakya on 2017/9/2.
//  Copyright © 2017年 Sakya. All rights reserved.
//

#import "UIView+CustomControlView.h"
#import <objc/runtime.h>

@implementation UIView (CustomControlView)
- (void)setDelegate:(id<SKPlayerCustomDelegate>)delegate {
    objc_setAssociatedObject(self, @selector(delegate), delegate, OBJC_ASSOCIATION_ASSIGN);
}

- (id<SKPlayerCustomDelegate>)delegate {
    return objc_getAssociatedObject(self, _cmd);
}
/**
 * 设置播放模型
 */
- (void)sk_playerModel:(SKPlayerModel *)playerModel {}

- (void)sk_playerShowOrHideControlView {}
/**
 * 显示top、bottom、lockBtn
 */
- (void)sk_playerShowControlView {}
/**
 * 隐藏top、bottom、lockBtn*/
- (void)sk_playerHideControlView {}

/**
 * 重置ControlView
 */
- (void)sk_playerResetControlView {}

/**
 * 切换分辨率时候调用此方法
 */
- (void)sk_playerResetControlViewForResolution {}

/**
 * 取消自动隐藏控制层view
 */
- (void)sk_playerCancelAutoFadeOutControlView {}

/**
 * 开始播放（隐藏placeholderImageView）
 */
- (void)sk_playerItemPlaying {}

/**
 * 播放完了
 */
- (void)sk_playerPlayEnd {}

/**
 * 是否有下载功能
 */
- (void)sk_playerHasDownloadFunction:(BOOL)sender {}

/**
 * 下载按钮状态
 */
- (void)sk_playerDownloadBtnState:(BOOL)state {}

/**
 * 是否有切换分辨率功能
 * @param resolutionArray 分辨率名称的数组
 */
- (void)sk_playerResolutionArray:(NSArray *)resolutionArray {}

/**
 * 播放按钮状态 (播放、暂停状态)
 */
- (void)sk_playerPlayBtnState:(BOOL)state {}

/**
 * 锁定屏幕方向按钮状态
 */
- (void)sk_playerLockBtnState:(BOOL)state {}

/**
 * 加载的菊花
 */
- (void)sk_playerActivity:(BOOL)animated {}

/**
 * 设置预览图
 
 * @param draggedTime 拖拽的时长
 * @param image       预览图
 */
- (void)sk_playerDraggedTime:(NSInteger)draggedTime sliderImage:(UIImage *)image {}

/**
 * 拖拽快进 快退
 
 * @param draggedTime 拖拽的时长
 * @param totalTime   视频总时长
 * @param forawrd     是否是快进
 * @param preview     是否有预览图
 */
- (void)sk_playerDraggedTime:(NSInteger)draggedTime totalTime:(NSInteger)totalTime isForward:(BOOL)forawrd hasPreview:(BOOL)preview {}

/**
 * 滑动调整进度结束结束
 */
- (void)sk_playerDraggedEnd {}

/**
 * 正常播放
 
 * @param currentTime 当前播放时长
 * @param totalTime   视频总时长
 * @param value       slider的value(0.0~1.0)
 */
- (void)sk_playerCurrentTime:(NSInteger)currentTime totalTime:(NSInteger)totalTime sliderValue:(CGFloat)value {}

/**
 * progress显示缓冲进度
 */
- (void)sk_playerSetProgress:(CGFloat)progress {}

/**
 * 视频加载失败
 */
- (void)sk_playerItemStatusFailed:(NSError *)error {}

/**
 * 小屏播放
 */
- (void)sk_playerBottomShrinkPlay {}

/**
 * 在cell播放
 */
- (void)sk_playerCellPlay {}

@end
