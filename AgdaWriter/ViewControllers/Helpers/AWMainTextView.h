//
//  AWMainTextView.h
//  AgdaWriter
//
//  Created by Marko Koležnik on 29. 01. 15.
//  Copyright (c) 2015 koleznik.net. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AWMainTextView : NSTextView <NSTextViewDelegate, NSApplicationDelegate> {
    BOOL initialize;
    NSDictionary * defaultAttributes;
    NSDictionary * goalsAttributes;
    NSMutableAttributedString * mutableAttributedString;
    NSMutableArray * goalsArray;
}

- (IBAction)save:(id)sender;



@end
