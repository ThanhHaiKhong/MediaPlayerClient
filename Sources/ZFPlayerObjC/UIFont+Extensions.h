//
//  UIFont+Extensions.h
//  
//
//  Created by Thanh Hai Khong on 6/6/24.
//

#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIFont (Extensions)

+ (UIFont *)roundedFontWithSize:(CGFloat)size weight:(UIFontWeight)weight;

@end

NS_ASSUME_NONNULL_END
