//
//  MonitoringSimplePlayerView.h
//  SKPlayer
//
//  Created by Sakya on 2017/9/3.
//  Copyright © 2017年 Sakya. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MonitoringSimplePlayerView : UIView
/**
 初始化视频播放
 
 @param title 播放标题
 @param videoPath 视频地址
 */
- (instancetype)initWithTitle:(NSString *)title
                    videoPath:(NSString *)videoPath;
//  暂时不用
- (void)setPlayerTitle:(NSString *)title
             videoPath:(NSString *)videoPath;


- (void)playerShow;
- (void)playerDismiss;
@end
