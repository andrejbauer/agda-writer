//
//  AWAgdaParser.h
//  AgdaWriter
//
//  Created by Marko Koležnik on 4. 02. 15.
//  Copyright (c) 2015 koleznik.net. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AWAgdaParser : NSObject

-(void) parseResponse:(NSString *)response;
+(NSDictionary *)parseAction:(NSString *) action;
+(NSArray *)makeArrayOfActions:(NSString *)reply;
@end