//
//  AWMainWindow.h
//  AgdaWriter
//
//  Created by Marko Koležnik on 15. 10. 14.
//  Copyright (c) 2014 koleznik.net. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AWMainWindow : NSWindow <NSApplicationDelegate,NSTextViewDelegate, NSTextDelegate>

@property IBOutlet NSTextView *mainTextView;
@property IBOutlet NSTextField *numberLabel;
@property (assign) IBOutlet id delegate;

- (void) textDidChange:(NSNotification *)notification;
@end
