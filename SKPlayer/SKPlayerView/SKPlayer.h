//
//  SKPlayer.h
//  SKPlayer
//
//  Created by Sakya on 2017/9/2.
//  Copyright © 2017年 Sakya. All rights reserved.
//

// player的单例
#define SKPlayerShared                      [SKPlayerStateView shareInstance]
// 屏幕的宽
#define ScreenWidth                         [[UIScreen mainScreen] bounds].size.width
// 屏幕的高
#define ScreenHeight                        [[UIScreen mainScreen] bounds].size.height
// 颜色值RGB
#define SKPLAYERRGBA(r,g,b,a)                       [UIColor colorWithRed:r/255.0f green:g/255.0f blue:b/255.0f alpha:a]
// 图片路径
#define SKPlayerSrcName(file)               [@"SKPlayer.bundle" stringByAppendingPathComponent:file]
#define SKPlayerFrameworkSrcName(file)      [@"Frameworks/SKPlayer.framework/SKPlayer.bundle" stringByAppendingPathComponent:file]
#define SKPlayerImage(file)                 [UIImage imageNamed:SKPlayerSrcName(file)] ? :[UIImage imageNamed:SKPlayerFrameworkSrcName(file)]


#import <Masonry/Masonry.h>
#import "SKPlayerModel.h"
#import "SKPlayerCustomDelegate.h"
#import "SKPlayerCustomControlView.h"
#import "SKPlayerStateView.h"
#import "UIWindow+CurrentViewController.h"
#import "SKPlayerView.h"
