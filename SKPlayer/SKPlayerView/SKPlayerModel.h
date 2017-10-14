//
//  SKPlayerModel.h
//  SKPlayer
//
//  Created by Sakya on 2017/9/2.
//  Copyright © 2017年 Sakya. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface SKPlayerModel : NSObject
/** 视频标题 */
@property (nonatomic, copy  ) NSString     *title;
/** 视频URL */
@property (nonatomic, strong) NSURL        *videoURL;
/** 视频封面本地图片 */
@property (nonatomic, strong) UIImage      *placeholderImage;
/** 播放器View的父视图（必须使用这个）*/
@property (nonatomic, weak  ) UIView       *fatherView;
/** 从xx秒开始播放视频(默认0) */
@property (nonatomic, assign) NSInteger    historyTime;

/**
 * 视频封面网络图片url
 * 如果和本地图片同时设置，则忽略本地图片，显示网络图片
 */
@property (nonatomic, copy  ) NSString     *placeholderImageURLString;

@end
