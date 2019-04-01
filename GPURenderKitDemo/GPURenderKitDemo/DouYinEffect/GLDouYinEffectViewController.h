//
//  GLDouYinEffectViewController.h
//  WEOpenGLDemo
//
//  Created by 刘海东 on 2019/2/19.
//  Copyright © 2019 Leo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseViewController.h"
NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger,DouYinEffectType)
{
    
    /** 抖音三屏带滤镜 */
    DouYinEffectType_GLImageThreePartition = 0,
    /** 抖音四分镜 */
    DouYinEffectType_GLImageFourPointsMirrorFilter = 1,
    
};





@interface GLDouYinEffectViewController : BaseViewController




@end

NS_ASSUME_NONNULL_END
