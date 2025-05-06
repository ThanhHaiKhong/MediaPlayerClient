//
//  UIFont+Extensions.m
//  
//
//  Created by Thanh Hai Khong on 6/6/24.
//

#import "UIFont+Extensions.h"

@implementation UIFont (Extensions)

+ (UIFont *)roundedFontWithSize:(CGFloat)size weight:(UIFontWeight)weight {
    UIFont *systemFont = [UIFont systemFontOfSize:size weight:weight];

    UIFontDescriptor *descriptor = [systemFont.fontDescriptor fontDescriptorWithDesign:UIFontDescriptorSystemDesignRounded];
    return [UIFont fontWithDescriptor:descriptor size:size];
}

@end
