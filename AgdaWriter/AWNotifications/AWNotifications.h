//
//  AWNotifications.h
//  AgdaWriter
//
//  Created by Marko Koležnik on 24. 01. 15.
//  Copyright (c) 2015 koleznik.net. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const fontSizeChanged;
extern NSString * const fontFamilyChanged;

@interface AWNotifications : NSObject

+ (void) notifyFontSizeChanged: (NSNumber *) fontSize;
+ (void) notifyFontFamilyChanged: (NSString *) fontFamily;

@end